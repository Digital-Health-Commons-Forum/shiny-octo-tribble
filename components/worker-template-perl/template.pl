#!/usr/bin/env perl

# Lang
use v5.30;
use warnings;
use strict;
use diagnostics;
use lib qw(lib/);

our $VERSION = '0.026';

# Third party libs
use POE;
use LWP::UserAgent;
use JSON::MaybeXS ':all';
use Data::Dumper::Concise;

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
my $api_url = 'http://127.0.0.1:3000/';

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
        my $api_target = $api_url . "worker";
        
        say "Stage(1): Sending worker info to OpenAPI server...";
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
            die "Failed to connect to OpenAPI server: ", $response->status_line;
        }
    }
    else {
        my $response = $ua->get($api_url);

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