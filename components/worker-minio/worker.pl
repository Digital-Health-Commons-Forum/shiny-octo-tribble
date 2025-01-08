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

sleep 5;

# Details about this worker
my $worker_info = {
    'name'          => 'worker-minio',
    'description'   => 'This is a template worker written in Perl.',
    'author'        => 'PGW',
    'offer'         => {
        'minio'         =>  'This worker offers simple functions for dealing with minio'
    },
    'version'       => $VERSION,
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

    my $minio_admin_key         = $ENV{'MINIO_ROOT_USER'};
    my $minio_admin_pass        = $ENV{'MINIO_ROOT_PASSWORD'};

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
        'minio_admin_key'       =>  $minio_admin_key,
        'minio_admin_pass'      =>  $minio_admin_pass,
        'minio_host'            =>  $minio_uri_host,
        'minio_port'            =>  $minio_uri_port,
        'minio_scheme'          =>  $minio_uri_scheme,
        'minio_secure'          =>  $minio_uri_secure,
        'minio_hostport'        =>  $minio_uri_hostport,
    }
};

# Signal handlers
$SIG{TERM} = sub {
    say STDERR "Received TERM signal, exiting...";
    POE::Kernel->stop();
    exit(0);
};

$SIG{INT} = sub {
    say STDERR "Received INT signal, exiting...";
    POE::Kernel->stop();
    exit(0);
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
        validate_minio => \&validate_minio,
        initilize_minio => \&initilize_minio,
    },
);

# Start the POE kernel
POE::Kernel->run();
exit;

# Start state for interacting with OpenAPI server
sub start_interact_with_openapi {
    my ($kernel,$heap,$session,$sender,$state) = @_[KERNEL,HEAP,SESSION,SENDER,STATE];
    $kernel->yield('interact_with_openapi');
}

# Function to interact with OpenAPI server
sub interact_with_openapi {
    my ($kernel,$heap,$session,$sender,$state) = @_[KERNEL,HEAP,SESSION,SENDER,STATE];

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
            $kernel->delay('interact_with_openapi', 5);
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
    my ($kernel,$heap,$session,$sender,$state) = @_[KERNEL,HEAP,SESSION,SENDER,STATE];
    $kernel->yield('additional_operation');
}

# Additional operation function
sub additional_operation {
    my ($kernel,$heap,$session,$sender,$state) = @_[KERNEL,HEAP,SESSION,SENDER,STATE];
    say STDERR "Waiting";

    if ($worker_info->{'data'}->{'stage'} == 2) {
        say STDERR "Stage(2): Validating minio presense & bucket 'media'...";
        $kernel->yield('validate_minio');
    }
    else {
        $kernel->delay('additional_operation', 5);
    }
}

# Validate Minio/S3 and check for 'media' bucket
sub validate_minio {
    my ($kernel,$heap,$session,$sender,$state) = @_[KERNEL,HEAP,SESSION,SENDER,STATE];
    say STDERR "Validating Minio/S3 connection and checking for access...";

    if ($worker_info->{'data'}->{'stage'} == 2) {
        $kernel->yield('initilize_minio');
    }
    elsif ($worker_info->{'data'}->{'stage'} == 3) {
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

        $heap->{'minio_client'} = $minio_client;
        
        my $response = $minio_client->buckets;
        if ($response) {
            say STDERR "Buckets available on Minio server:";
            foreach my $bucket ( @{ $response->{buckets} } ) {
            say STDERR "Bucket: " . $bucket->bucket;
            }
            $worker_info->{'data'}->{'stage'} = 3;
        } else {
            say STDERR "Failed to list buckets.";
        }
    }

    $kernel->delay('additional_operation', 5);
}

sub initilize_minio {
    my ($kernel,$heap,$session,$sender,$state) = @_[KERNEL,HEAP,SESSION,SENDER,STATE];
    say STDERR "Initializing Minio/S3 connection...";

    eval {
        my $alias_cmd = sprintf(
            'mc alias set worker %s %s %s',
            $minio_credentials->{'minio_scheme'} . '://' . $minio_credentials->{'minio_hostport'},
            $minio_credentials->{'minio_admin_key'},
            $minio_credentials->{'minio_admin_pass'}
        );
        say STDERR "Alias command: $alias_cmd";
        system($alias_cmd) == 0 or die "Failed to set alias: $!";

        my $user_cmd = sprintf(
            'mc admin user add worker %s %s',
            $minio_credentials->{'minio_key_id'},
            $minio_credentials->{'minio_access_key'},
        );
        say STDERR "User command: $user_cmd";
        system($user_cmd) == 0 or die "Failed to add host config: $!";

        my $permission_cmd = sprintf(
            'mc admin policy attach worker readwrite --user=%s',
            $minio_credentials->{'minio_key_id'},
        );
        say STDERR "Permission command: $permission_cmd";
        system($permission_cmd) == 0 or die "Failed to add host config: $!";

        my $bucket_cmd = 'mc mb worker/media 2>&1';
        say STDERR "Bucket command: $bucket_cmd";
        my $output = `$bucket_cmd`;
        if ($output =~ m#(?:Bucket created successfully|you already own it)#) {
            say STDERR "Bucket 'media' created successfully";
            $worker_info->{'data'}->{'stage'} = 3;
            $kernel->yield('validate_minio');
        }
        else {
            die "Failed to create bucket: $output";
        }
    };
    if ($@) {
        say STDERR "Error during Minio setup: $@";
    }
}
