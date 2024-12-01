#!/usr/bin/env perl

use v5.30;
use warnings;
use strict;

use lib qw(lib/);

use YAML::XS 'LoadFile';
use Mojo::JSON qw(decode_json);
use Mojo::File 'path';
use Mojo::Util;
use Mojolicious::Lite -signatures;
use Mojolicious::Plugin::OpenAPI;
use DBIx::Class::Candy;
use Mojo::Core::Schema;

# Load the OpenAPI specification
plugin OpenAPI => {url => 'schema.yml'};

# Validate the schema against the handlers
self_test_schema();

# Define routes based on the OpenAPI specification

## Make the application return 
get '/' => sub ($c) {
    my $routes = [
        { method => 'POST', path => '/worker', description => 'Create a new worker process' },
        { method => 'GET', path => '/worker/:id', description => 'Get a worker process by ID' },
        { method => 'PUT', path => '/worker/:id', description => 'Update a worker process' },
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

# Database setup
helper db => sub {
    state $schema = Mojo::Core::Schema->connect('dbi:SQLite:dbname=core.db');
};

# Define routes
get '/worker/:id' => sub ($c) {
    my $id = $c->param('id');
    my $worker = $c->db->resultset('Worker')->find($id);
    return $c->render(openapi => {error => 'Worker not found'}, status => 404) unless $worker;
    $c->render(openapi => {id => $worker->id, name => $worker->name, status => $worker->status});
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
    my $keywords = $c->req->json->{keywords};
    # Simulate finding a document ID based on keywords
    my $docid = 'doc123';
    $c->render(openapi => {docid => $docid});
}, 'findDocument';

get '/media/tags' => sub ($c) {
    my $docid = $c->param('docid');
    # Simulate retrieving tags for a document ID
    my $tags = ['tag1', 'tag2', 'tag3'];
    $c->render(openapi => {tags => $tags});
}, 'getTags';

post '/media/filename' => sub ($c) {
    my $docid = $c->req->json->{docid};
    # Simulate retrieving filename for a document ID
    my $filename = 'document.pdf';
    $c->render(openapi => {filename => $filename});
}, 'getFilename';

# Start the Mojolicious app
app->start;

sub self_test_schema {
    # This does not work and does not detect if a handler is missing!
    # Leave it in for the moment as its not required, but it should
    # be looked into, I think we need a way of finding all the handlers 
    # within code and adding the comparison.

    # Load and parse the OpenAPI specification
    my $schema = LoadFile('schema.yml');

    # Extract paths and operations from the schema
    my %schema_operations;
    for my $path (keys %{$schema->{paths}}) {
        for my $method (keys %{$schema->{paths}{$path}}) {
            my $operation_id = $schema->{paths}{$path}{$method}{operationId};
            $schema_operations{$operation_id} = 1 if $operation_id;
        }
    }

    # Extract handlers from the code
    my %code_operations = map { $_ => 1 } qw(
        createWorker
        getWorkerById
        updateWorker
        deleteWorker
        loginUser
        logoutUser
        getUserById
        findDocument
        getTags
        getFilename
    );

    # Validate that all schema operations have corresponding handlers
    for my $operation_id (keys %schema_operations) {
        die "Missing handler for operation: $operation_id" unless $code_operations{$operation_id};
    }
}
