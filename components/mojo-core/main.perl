#!/usr/bin/env perl

use v5.30;
use warnings;
use strict;

use YAML::XS 'LoadFile';

use Mojo::JSON qw(decode_json);
use Mojo::File 'path';
use Mojo::Util;

use Mojolicious::Lite -signatures;
use Mojolicious::Plugin::OpenAPI;

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
    ];
    $c->render(json => {endpoints => $routes});
};

any '/worker' => sub ($c) {
    $c->render(openapi => {id => 1, name => 'Worker 1', status => 'active'});
}, 'createWorker';

get '/worker/:id' => sub ($c) {
    my $id = $c->param('id');
    $c->render(openapi => {id => $id, name => 'Worker 1', status => 'active'});
}, 'getWorkerById';

put '/worker/:id' => sub ($c) {
    my $id = $c->param('id');
    $c->render(openapi => {id => $id, name => 'Updated Worker', status => 'active'});
}, 'updateWorker';

del '/worker/:id' => sub ($c) {
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
    );

    # Validate that all schema operations have corresponding handlers
    for my $operation_id (keys %schema_operations) {
        die "Missing handler for operation: $operation_id" unless $code_operations{$operation_id};
    }
}
