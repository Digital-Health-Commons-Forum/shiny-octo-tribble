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

# OpenAPI server URL
my $api_url = 'http://127.0.0.1:8080/api';

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
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($api_url);

    if ($response->is_success) {
        my $data = decode_json($response->decoded_content);
        print "Received data from OpenAPI server: ", $data, "\n";
    } else {
        die "Failed to connect to OpenAPI server: ", $response->status_line;
    }
}

# Start state for additional operation
sub start_additional_operation {
    $_[KERNEL]->yield('additional_operation');
}

# Additional operation function
sub additional_operation {
    print "Performing additional operation...\n";
    # Add your additional operation code here
}