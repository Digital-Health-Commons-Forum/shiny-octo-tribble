#!/usr/bin/env perl

# Lang
use v5.30;
use warnings;
use strict;
use diagnostics;
use lib qw(lib/);

# Version
our $VERSION = '0.026';

# Core 
use Env;
use Carp qw(cluck shortmess longmess croak confess);
use Carp::Always;

# 3rd Party
use Const::Fast;
use DBIx::Class::Candy;
use YAML::XS 'LoadFile';
use Mojo::JSON qw(decode_json);
use Mojo::File 'path';
use Mojo::Util;
use Mojolicious::Lite -signatures;
use Mojolicious::Plugin::OpenAPI;
use Net::Amazon::S3;
use URI;

# Local
use Mojo::Core::Schema;

# Debugging
use Data::Dumper::Concise;
diagnostics->disable;


# Database setup
helper db => sub {
    state $schema = Mojo::Core::Schema->connect('dbi:SQLite:dbname=core.db');
};

# Load the OpenAPI specification
# app->plugin(OpenAPI => {url  => app->home->rel_file('schema.js') });
plugin OpenAPI => {url => 'file:///perl/schema.js'};
app->secrets(['A1B2c3d$']);

# Collect/create all the minio information
const my $minio_credentials => do {
    my $minio_access_key        = $ENV{'MINIO_ACCESS_KEY'};
    my $minio_secret_key        = $ENV{'MINIO_SECRET_KEY'};
    my $minio_uri               = $ENV{'MINIO_URI'}||'http://127.0.0.1:9000';

    my $minio_uri_obj           = URI->new($minio_uri);
    my $minio_uri_host          = $minio_uri_obj->host || '127.0.0.1';
    my $minio_uri_port          = $minio_uri_obj->port || 9000;
    my $minio_uri_scheme        = $minio_uri_obj->scheme =~ m#^http|https$#i ? lc($minio_uri_obj->scheme) : 'http';
    my $minio_uri_secure        = $minio_uri_scheme =~ m#^https#i ? 1 : 0;

    my $minio_uri_hostport      = join(':',$minio_uri_host,$minio_uri_port);
    my ($uri_user,$uri_pass)    = split(':',$minio_uri_obj->userinfo||'');
    $minio_access_key           ||= $uri_user ? $uri_user : '';
    $minio_secret_key           ||= $uri_pass ? $uri_pass : '';

    if (!$minio_access_key || !$minio_secret_key) {
        croak('Missing Minio credentials');
    }

    {
        'minio_key_id'          =>  $minio_access_key,
        'minio_access_key'      =>  $minio_secret_key,
        'minio_host'            =>  $minio_uri_host,
        'minio_port'            =>  $minio_uri_port,
        'minio_scheme'          =>  $minio_uri_scheme,
        'minio_secure'          =>  $minio_uri_secure,
        'minio_hostport'        =>  $minio_uri_hostport,
    }
};

my $minio_client = do {
    my $s3 = Net::Amazon::S3->new(
        {
            aws_access_key_id     => $minio_credentials->{'minio_key_id'},
            aws_secret_access_key => $minio_credentials->{'minio_access_key'},
            host                  => $minio_credentials->{'minio_hostport'},
            secure                => $minio_credentials->{'minio_secure'},
        }
    );
    Net::Amazon::S3::Client->new( s3 => $s3 )
};

# Database setup
helper db => sub {
    state $schema = Mojo::Core::Schema->connect('dbi:SQLite:dbname=core.db');
};

# Development dictionary
my $dev_fake_minio = {
    'filename_by_name' =>  {
        'file1'     =>  1,
        'file2'     =>  2,
        'file3'     =>  3,
        'fancyfile' =>  4,
    },
    'filename_by_id' => [
        undef,
        'file1',
        'file2',
        'file3',
        'fancyfile',
    ],
    'tags'  =>  [
        ['file1',[1]], # Docid = 1, filename_by_name[1]
        ['file2',[2]], # Docid = 2, filename_by_name[2]
        ['file3',[3]], # Docid = 3, filename_by_name[3]
        ['medical',[1]],
        ['alchemy',[2,4]],
        ['uber',[2]] # Docid = 2, filename_by_name[2]
    ],
    'details' => [
        { 
            'filename' => 'medical blood thingy.pdf',
            # Create tags from minio lookup
            'tags' => ['file1','medical','alchemy']
        },
        { 
            'filename' => 'gork or mork an analysis.docx',
            'tags' => ['file2','alchemy','uber']
        },
        { 
            'filename' => 'freebsd linux windows a three way tale.txt',
            'tags' => ['file3','alchemy']
        },
        { 
            'filename' => 'cookie.png',
            'tags' => ['fancyfile','alchemy']
        },
    ]
};

# Load the OpenAPI specification
plugin OpenAPI => {url => 'schema.js'};
diagnostics->disable;
app->secrets(['A1B2c3d$']);

# Make the application return 
get '/' => sub ($c) {
    my $routes = [
        { method => 'POST', path => '/worker', description => 'Create a new worker process' },
        { method => 'GET', path => '/worker/:id', description => 'Get a worker process by ID' },
        { method => 'PUT', path => '/worker/:id', description => 'Update a worker process' },
        { method => 'POST', path => '/worker/ready', description => 'Notifies the webserver that a worker process is ready.' },
        { method => 'DELETE', path => '/worker/:id', description => 'Delete a worker process' },
        { method => 'POST', path => '/auth/login', description => 'User login' },
        { method => 'POST', path => '/auth/logout', description => 'User logout' },
        { method => 'GET', path => '/user/:id', description => 'Get user profile by ID' },
        { method => 'POST', path => '/media/find', description => 'Find document by keywords' },
        { method => 'GET', path => '/media/tags', description => 'Get tags by document ID' },
        { method => 'POST', path => '/media/filename', description => 'Get filename by document ID' },
    ];
    $c->render(json => {endpoints => $routes});
};

# Test
post '/echo' => sub {
  # Validate input request or return an error document
  my $c = shift->openapi->valid_input or return;
  # Generate some data
  my $data = {body => $c->req->json};
  # Validate the output response and render it to the user agent
  # using a custom "openapi" handler.
  $c->render(openapi => $data);
}, 'echo';

# Define routes
post '/workers' => sub ($c) {
    $c->render(
        openapi => {
            token => 'session_token'
        }
    );
}, 'loginUser';

get '/worker/:id' => sub ($c) {
    my $id = $c->param('id');
    my $worker = $c->db->resultset('Worker')->find($id);
    # return $c->render(openapi => {error => 'Worker not found'}, status => 404) unless $worker;
    $c->render(json => {id => $worker->id, name => $worker->name, status => $worker->status});
}, 'getWorkerById';

put '/worker/:id' => sub ($c) {
    my $id = $c->param('id');
    my $worker = $c->db->resultset('Worker')->find($id);
    return $c->render(openapi => {error => 'Worker not found'}, status => 404) unless $worker;
    $worker->update({name => 'Updated Worker', status => 'active'});
    $c->render(openapi => {id => $worker->id, name => $worker->name, status => $worker->status});
}, 'updateWorker';

del '/worker/:id' => sub ($c) {
    my $id = $c->param('id');
    my $worker = $c->db->resultset('Worker')->find($id);
    return $c->render(openapi => {error => 'Worker not found'}, status => 404) unless $worker;
    $worker->delete;
    $c->render(openapi => undef, status => 204);
}, 'deleteWorker';

post '/worker/ready' => sub ($c) {
    $c->render(
        openapi => {
            token => 'session_token'
        }
    );
}, 'workerReady';

post '/auth/login' => sub ($c) {
    $c->render(openapi => {token => 'session_token'});
}, 'loginUser';

post '/auth/logout' => sub ($c) {
    $c->render(openapi => undef, status => 204);
}, 'logoutUser';

get '/user/:id' => sub ($c) {
    my $id = $c->param('id');
    $c->render(openapi => {id => $id, name => 'User Name', email => 'user@example.com', created_at => '2023-10-01T00:00:00Z'});
}, 'getUserById';

post '/media/find' => sub ($c) {
    # $dev_fake_minio     
    my @results;
    my @keywords = @{$c->req->json->{'keywords'}||[]};
    foreach my $keyword (@keywords) {
        say STDERR "Looking for: $keyword";
        my $loop_count = 0;
        foreach my $local_keyword (@{$dev_fake_minio->{'tags'}}) {
            my $local_tag = $local_keyword->[0];
            say STDERR "Trying: '$local_tag' to '$keyword' (test)";
            if ($local_tag =~ m#\Q$keyword\E#) {
                say STDERR "Find: $keyword to $local_tag (match)";
                my @matched_docs = @{$dev_fake_minio->{'tags'}->[$loop_count]->[1]};
                say STDERR "Would match: ".join(',',@matched_docs);
                foreach my $matched_id (@matched_docs) {
                    $results[$matched_id]++;
                }
                say STDERR "Results: ".Dumper(\@results);
            }
            $loop_count++;
        }
    }
    # Simulate finding a document ID based on keywords
    my $docid = 'doc123';
    $c->render(json => {docid => \@results});
}, 'findDocument';

get '/media/tags' => sub ($c) {
    my $docid = $c->param('docid');
    # Simulate retrieving tags for a document ID
    my $tags = ['tag1', 'tag2', 'tag3'];
    $c->render(json => {tags => $tags});
}, 'getTags';

get '/media/filename' => sub ($c) {
    my $docid = $c->param('docid');

    if ($docid !~ m#^\d+$#) {
        return $c->render(
            openapi => {
                error => 'Invalid docid'
            },
            status => 400
        );
    }
    elsif (!$dev_fake_minio->{'filename_by_id'}->[$docid]) {
        return $c->render(
            openapi => {
                error => 'Could not find document',
                status => 404 
            },  
        );
    }
    else {
        my $filename = $dev_fake_minio->{'filename_by_id'}->[$docid];
        $c->render(json => {filename => $filename});
    }
}, 'getFilename';

app->start;
