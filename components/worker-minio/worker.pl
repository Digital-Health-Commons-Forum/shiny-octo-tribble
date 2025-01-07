#!/usr/bin/env perl

# Lang
use v5.30;
use warnings;
use strict;
use diagnostics;
use lib qw(lib/);

our $VERSION = '0.026';

# Third party libs
use Const::Fast;
use POE;
use LWP::UserAgent;
use JSON::MaybeXS ':all';
use Data::Dumper::Concise;
use Net::Amazon::S3;

# Details about this worker
my $worker_info = {
    'name'          => 'worker-template-perl',
    'description'   => 'This is a template worker written in Perl.',
    'author'        => 'PGW'
};

# A place to store worker state
my $worker_state = {
    'status'        => 'running',
    'progress'      => 0,
    'message'       => 'Worker is running...',
    'data'          => {
        'stage'    => 1,
    }
};

# OpenAPI server URL
my $api_url = URI->new($ENV{'MOJO_API_UI'}||'http://mojo:3000/');

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

# Session to interact with OpenAPI server
POE::Session->create(
    inline_states => {
        _start => \&start_interact_with_openapi,
        interact_with_openapi => \&interact_with_openapi,
    },
);

# Session for additional operation
POE::Session->create(
    inline_states => {
        _start => \&start_additional_operation,
        additional_operation => \&additional_operation,
    },
);

# Start the POE kernel
POE::Kernel->run();
exit;

# Start state for interacting with OpenAPI server
sub start_interact_with_openapi {
    $_[KERNEL]->yield('interact_with_openapi');
}

# Function to interact with OpenAPI server
sub interact_with_openapi {
    # Should really use a proper HTTP client library here, but this is just a template
    my $ua = LWP::UserAgent->new;

    # If we are state 1, we need to make a POST request
    # and tell OpenAPI server that we are ready to start
    # and who we are
    if ($worker_state->{'data'}->{'stage'} == 1) {
        my $payload = encode_json($worker_info);
        my $api_target = $api_url->as_string . "/worker";
        
        say STDERR "Stage(1): Sending worker info to OpenAPI server... ($api_target)";
        my $response = $ua->post(
            $api_target,
            'Content-Type' => 'application/json',
            'Content' => $payload
        );

        if ($response->is_success) {
            my $data = decode_json($response->decoded_content);
            say "Received data from OpenAPI server: ", Dumper $data;
            $worker_info->{'data'}->{'stage'} = 2;
        } else {
            say STDERR "Failed to connect to OpenAPI server: ", $response->status_line;
            say STDERR "Will retry in 5 seconds...";
            $_[KERNEL]->delay('interact_with_openapi', 5);
        }
    }
    else {
        my $response = $ua->get($api_url->as_string);

        if ($response->is_success) {
            my $data = decode_json($response->decoded_content);
            say "Received data from OpenAPI server: ", Dumper $data;
        } else {
            die "Failed to connect to OpenAPI server: ", $response->status_line;
        }
    }
}

# Start state for additional operation
sub start_additional_operation {
    $_[KERNEL]->yield('additional_operation');
}

# Additional operation function
sub additional_operation {
    say "Performing additional operation...\n";
    # Add your additional operation code here
}