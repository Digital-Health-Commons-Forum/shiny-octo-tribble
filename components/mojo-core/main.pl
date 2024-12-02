#!/usr/bin/env perl

our $VERSION = 'v0.1_3';

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
use Amazon::S3;

# Wait to make sure all other components are up
# swap this for aep later
say "Waiting for other components to start...";
sleep 5;

# Load the OpenAPI specification
plugin OpenAPI => {url => 'data:///schema.yml'};

# Create a connector to S3/Minio
my $minio_access_key_id     = "minioadmin";
my $minio_secret_access_key = "minioadmin";
my $s3 = Amazon::S3->new(
    {   
      aws_access_key_id     => $minio_access_key_id,
      aws_secret_access_key => $minio_secret_access_key,
      retry                 => 1,
      host                  => 'http://minio:9000',
    }
);
my $response = $s3->buckets;
# create a bucket
my $bucket_name = $minio_access_key_id . '-net-amazon-s3-test';
my $bucket = $s3->add_bucket( { bucket => $bucket_name } )
    or die $s3->err . ": " . $s3->errstr;
# delete bucket
$bucket->delete_bucket;


# Validate the schema against the handlers
# self_test_schema() - fix me, cannot find the schema in docker with an explicit path???
# GET /app/schema.yml: Not Found at local/lib/perl5/JSON/Validator/Store.pm line 127.
# root@8002ba33191c:/app# ls -la /app/schema.yml
# lrwxrwxrwx 1 root root 20 Dec  2 17:13 /app/schema.yml -> ../../etc/schema.yml

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

__DATA__
@@ schema.yml
swagger: '2.0'
info:
  version: "0.1.3"
  title: Worker Process API
  description: API for worker processes to connect and send/receive JSON encoded objects.
  termsOfService: http://example.com/terms/
  contact:
    name: API Support
    email: support@example.com
  license:
    name: AGPL 3.0
    url: https://www.gnu.org/licenses/agpl-3.0.html
host: api.example.com
basePath: /v1
schemes:
  - https
paths:
  /worker:
    post:
      summary: Create a new worker process
      description: Creates a new worker process that can send and receive JSON encoded objects.
      operationId: createWorker
      tags:
        - Worker
      parameters:
        - in: body
          name: worker
          description: The worker process to create
          required: true
          schema:
            $ref: '#/definitions/Worker'
      responses:
        '201':
          description: Worker created successfully
          schema:
            $ref: '#/definitions/Worker'
        '400':
          description: Invalid input
        '500':
          description: Internal server error
  /worker/{id}:
    get:
      summary: Get a worker process by ID
      description: Retrieve details of a specific worker process.
      operationId: getWorkerById
      tags:
        - Worker
      parameters:
        - name: id
          in: path
          required: true
          type: string
        - name: querytype
          in: query
          required: false
          type: string
          description: Specifies what is being queried (e.g., "details", "status")
      responses:
        '200':
          description: Worker details
          schema:
            $ref: '#/definitions/Worker'
        '404':
          description: Worker not found
        '500':
          description: Internal server error
    put:
      summary: Update a worker process
      description: Update the details of an existing worker process.
      operationId: updateWorker
      tags:
        - Worker
      parameters:
        - name: id
          in: path
          required: true
          type: string
        - in: body
          name: worker
          description: The updated worker process details
          required: true
          schema:
            $ref: '#/definitions/Worker'
      responses:
        '200':
          description: Worker updated successfully
          schema:
            $ref: '#/definitions/Worker'
        '400':
          description: Invalid input
        '404':
          description: Worker not found
        '500':
          description: Internal server error
    delete:
      summary: Delete a worker process
      description: Deletes a specific worker process.
      operationId: deleteWorker
      tags:
        - Worker
      parameters:
        - name: id
          in: path
          required: true
          type: string
      responses:
        '204':
          description: Worker deleted successfully
        '404':
          description: Worker not found
        '500':
          description: Internal server error
  /auth/login:
    post:
      summary: User login
      description: Authenticates a user and returns a session token.
      operationId: loginUser
      tags:
        - Authentication
      parameters:
        - in: body
          name: credentials
          description: User login credentials
          required: true
          schema:
            $ref: '#/definitions/LoginCredentials'
      responses:
        '200':
          description: Login successful
          schema:
            $ref: '#/definitions/Session'
        '401':
          description: Unauthorized
        '500':
          description: Internal server error
  /auth/logout:
    post:
      summary: User logout
      description: Logs out the current user and invalidates the session token.
      operationId: logoutUser
      tags:
        - Authentication
      responses:
        '204':
          description: Logout successful
        '401':
          description: Unauthorized
        '500':
          description: Internal server error

  /media/find:
    post:
      summary: Find document by keywords
      description: Returns a document ID based on provided keywords.
      operationId: findDocument
      tags:
        - Media
      parameters:
        - in: body
          name: keywords
          description: Keywords to search for the document
          required: true
          schema:
            type: object
            properties:
              keywords:
                type: array
                items:
                  type: string
      responses:
        '200':
          description: Document ID found
          schema:
            type: object
            properties:
              docid:
                type: string
        '400':
          description: Invalid input
        '500':
          description: Internal server error
  /media/tags:
    get:
      summary: Get tags by document ID
      description: Returns tags associated with a specific document ID.
      operationId: getTags
      tags:
        - Media
      parameters:
        - name: docid
          in: query
          description: Document ID to get tags for
          required: true
          type: string
      responses:
        '200':
          description: Tags retrieved successfully
          schema:
            type: object
            properties:
              tags:
                type: array
                items:
                  type: string
        '400':
          description: Invalid input
        '404':
          description: Document not found
        '500':
          description: Internal server error
  /media/filename:
    post:
      summary: Get filename by document ID
      description: Returns the filename associated with a specific document ID.
      operationId: getFilename
      tags:
        - Media
      parameters:
        - in: body
          name: docid
          description: Document ID to get filename for
          required: true
          schema:
            type: object
            properties:
              docid:
                type: string
      responses:
        '200':
          description: Filename retrieved successfully
          schema:
            type: object
            properties:
              filename:
                type: string
        '400':
          description: Invalid input
        '404':
          description: Document not found
        '500':
          description: Internal server error

  /user/{id}:
    get:
      summary: Get user profile by ID
      description: Retrieve the profile of a specific user.
      operationId: getUserById
      tags:
        - User
      parameters:
        - name: id
          in: path
          required: true
          type: string
      responses:
        '200':
          description: User profile
          schema:
            $ref: '#/definitions/UserProfile'
        '404':
          description: User not found
        '500':
          description: Internal server error
definitions:
  Worker:
    type: object
    required:
      - id
      - name
      - status
    properties:
      id:
        type: string
        description: Unique identifier for the worker process
      name:
        type: string
        description: Name of the worker process
      status:
        type: string
        description: Current status of the worker process
        enum:
          - active
          - inactive
          - paused
  LoginCredentials:
    type: object
    required:
      - username
      - password
    properties:
      username:
        type: string
        description: Username for logging in
      password:
        type: string
        description: Password for logging in
  Session:
    type: object
    properties:
      token:
        type: string
        description: Session token
  UserProfile:
    type: object
    properties:
      id:
        type: string
      name:
        type: string
      email:
        type: string
      created_at:
        type: string
        format: date-time
  Error:
    type: object
    required:
      - code
      - message
    properties:
      code:
        type: integer
        format: int32
      message:
        type: string


# sub self_test_schema {
#     # This does not work and does not detect if a handler is missing!
#     # Leave it in for the moment as its not required, but it should
#     # be looked into, I think we need a way of finding all the handlers 
#     # within code and adding the comparison.

#     # Load and parse the OpenAPI specification
#     my $schema = LoadFile('/app/schema.yml');

#     # Extract paths and operations from the schema
#     my %schema_operations;
#     for my $path (keys %{$schema->{paths}}) {
#         for my $method (keys %{$schema->{paths}{$path}}) {
#             my $operation_id = $schema->{paths}{$path}{$method}{operationId};
#             $schema_operations{$operation_id} = 1 if $operation_id;
#         }
#     }

#     # Extract handlers from the code
#     my %code_operations = map { $_ => 1 } qw(
#         createWorker
#         getWorkerById
#         updateWorker
#         deleteWorker
#         loginUser
#         logoutUser
#         getUserById
#         findDocument
#         getTags
#         getFilename
#     );

#     # Validate that all schema operations have corresponding handlers
#     for my $operation_id (keys %schema_operations) {
#         die "Missing handler for operation: $operation_id" unless $code_operations{$operation_id};
#     }
# }
