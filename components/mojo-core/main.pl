#!/usr/bin/env perl

our $VERSION = '0.026';

use v5.30;
use warnings;
use strict;

use lib qw(lib/);
use Env;
use Data::Dumper;
use Readonly;
use diagnostics;

use YAML::XS 'LoadFile';
use Mojo::JSON qw(decode_json);
use Mojo::File 'path';
use Mojo::Util;
use Mojolicious::Lite -signatures;
use Mojolicious::Plugin::OpenAPI;
use DBIx::Class::Candy;
use Mojo::Core::Schema;
use Net::Amazon::S3;
use URI;

# Database setup
helper db => sub {
    state $schema = Mojo::Core::Schema->connect('dbi:SQLite:dbname=core.db');
};

# Load the OpenAPI specification
plugin OpenAPI => {url => 'data:///schema.js'};
diagnostics->disable;
app->secrets(['A1B2c3d$']);

# Collect/create all the minio information
Readonly::Scalar my $minio_credentials => do {
    my $minio_access_key_id     = $ENV{'MINIO_ROOT_USER'}||'minioadmin';
    my $minio_secret_access_key = $ENV{'MINIO_ROOT_PASSWORD'}||'minioadmin';
    my $minio_uri               = $ENV{'MINIO_URI'}||'http://127.0.0.1:9000';

    my $minio_uri_obj           = URI->new($minio_uri);
    my $minio_uri_host          = $minio_uri_obj->host;
    my $minio_uri_port          = $minio_uri_obj->port || 9000;
    my $minio_uri_scheme        = $minio_uri_obj->scheme;
    my $minio_uri_secure        = $minio_uri_scheme =~ m#^https#i ? 1 : 0;
    my $minio_uri_hostport      = join(':',$minio_uri_host,$minio_uri_port);

    {
        'minio_key_id'          =>  $minio_access_key_id,
        'minio_access_key'      =>  $minio_secret_access_key,
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
plugin OpenAPI => {url => 'data:///schema.js'};
diagnostics->disable;
app->secrets(['A1B2c3d$']);

# Make the application return 
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

# Test
post "/echo" => sub {
  # Validate input request or return an error document
  my $c = shift->openapi->valid_input or return;
  # Generate some data
  my $data = {body => $c->req->json};
  # Validate the output response and render it to the user agent
  # using a custom "openapi" handler.
  $c->render(openapi => $data);
}, "echo";

# Define routes
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

__DATA__
@@ schema.js
{
  "swagger": "2.0",
  "info": {
    "version": "0.1.3",
    "title": "Worker Process API",
    "description": "API for worker processes to connect and send/receive JSON encoded objects.",
    "termsOfService": "http://example.com/terms/",
    "contact": {
      "name": "API Support",
      "email": "support@example.com"
    },
    "license": {
      "name": "AGPL 3.0",
      "url": "https://www.gnu.org/licenses/agpl-3.0.html"
    }
  },
  "basePath": "/api",
  "paths": {
    "/echo": {
      "post": {
        "x-mojo-name": "echo",
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "schema": {
              "type": "object"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Echo response",
            "schema": {
              "type": "object"
            }
          }
        }
      }
    },
    "/worker": {
      "post": {
        "summary": "Create a new worker process",
        "description": "Creates a new worker process that can send and receive JSON encoded objects.",
        "operationId": "createWorker",
        "tags": [
          "Worker"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "worker",
            "description": "The worker process to create",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Worker"
            }
          }
        ],
        "responses": {
          "201": {
            "description": "Worker created successfully",
            "schema": {
              "$ref": "#/definitions/Worker"
            }
          },
          "400": {
            "description": "Invalid input"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/worker/{id}": {
      "get": {
        "summary": "Get a worker process by ID",
        "description": "Retrieve details of a specific worker process.",
        "operationId": "getWorkerById",
        "tags": [
          "Worker"
        ],
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "querytype",
            "in": "query",
            "required": false,
            "type": "string",
            "description": "Specifies what is being queried (e.g., \"details\", \"status\")"
          }
        ],
        "responses": {
          "200": {
            "description": "Worker details",
            "schema": {
              "$ref": "#/definitions/Worker"
            }
          },
          "404": {
            "description": "Worker not found"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      },
      "put": {
        "summary": "Update a worker process",
        "description": "Update the details of an existing worker process.",
        "operationId": "updateWorker",
        "tags": [
          "Worker"
        ],
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "in": "body",
            "name": "worker",
            "description": "The updated worker process details",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Worker"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Worker updated successfully",
            "schema": {
              "$ref": "#/definitions/Worker"
            }
          },
          "400": {
            "description": "Invalid input"
          },
          "404": {
            "description": "Worker not found"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      },
      "delete": {
        "summary": "Delete a worker process",
        "description": "Deletes a specific worker process.",
        "operationId": "deleteWorker",
        "tags": [
          "Worker"
        ],
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "204": {
            "description": "Worker deleted successfully"
          },
          "404": {
            "description": "Worker not found"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/auth/login": {
      "post": {
        "summary": "User login",
        "description": "Authenticates a user and returns a session token.",
        "operationId": "loginUser",
        "tags": [
          "Authentication"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "credentials",
            "description": "User login credentials",
            "required": true,
            "schema": {
              "$ref": "#/definitions/LoginCredentials"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Login successful",
            "schema": {
              "$ref": "#/definitions/Session"
            }
          },
          "401": {
            "description": "Unauthorized"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/auth/logout": {
      "post": {
        "summary": "User logout",
        "description": "Logs out the current user and invalidates the session token.",
        "operationId": "logoutUser",
        "tags": [
          "Authentication"
        ],
        "responses": {
          "204": {
            "description": "Logout successful"
          },
          "401": {
            "description": "Unauthorized"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/media/find": {
      "post": {
        "summary": "Find document by keywords",
        "description": "Returns a document ID based on provided keywords.",
        "operationId": "findDocument",
        "tags": [
          "Media"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "keywords",
            "description": "Keywords to search for the document",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "keywords": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Document ID found",
            "schema": {
              "type": "object",
              "properties": {
                "docid": {
                  "type": "string"
                }
              }
            }
          },
          "400": {
            "description": "Invalid input"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/media/tags": {
      "get": {
        "summary": "Get tags by document ID",
        "description": "Returns tags associated with a specific document ID.",
        "operationId": "getTags",
        "tags": [
          "Media"
        ],
        "parameters": [
          {
            "name": "docid",
            "in": "query",
            "description": "Document ID to get tags for",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "Tags retrieved successfully",
            "schema": {
              "type": "object",
              "properties": {
                "tags": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "400": {
            "description": "Invalid input"
          },
          "404": {
            "description": "Document not found"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/media/filename": {
      "post": {
        "summary": "Get filename by document ID",
        "description": "Returns the filename associated with a specific document ID.",
        "operationId": "getFilename",
        "tags": [
          "Media"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "docid",
            "description": "Document ID to get filename for",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "docid": {
                  "type": "string"
                }
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Filename retrieved successfully",
            "schema": {
              "type": "object",
              "properties": {
                "filename": {
                  "type": "string"
                }
              }
            }
          },
          "400": {
            "description": "Invalid input"
          },
          "404": {
            "description": "Document not found"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    },
    "/user/{id}": {
      "get": {
        "summary": "Get user profile by ID",
        "description": "Retrieve the profile of a specific user.",
        "operationId": "getUserById",
        "tags": [
          "User"
        ],
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "User profile",
            "schema": {
              "$ref": "#/definitions/UserProfile"
            }
          },
          "404": {
            "description": "User not found"
          },
          "500": {
            "description": "Internal server error"
          }
        }
      }
    }
  },
  "definitions": {
    "Worker": {
      "type": "object",
      "required": [
        "id",
        "name",
        "status"
      ],
      "properties": {
        "id": {
          "type": "string",
          "description": "Unique identifier for the worker process"
        },
        "name": {
          "type": "string",
          "description": "Name of the worker process"
        },
        "status": {
          "type": "string",
          "description": "Current status of the worker process",
          "enum": [
            "active",
            "inactive",
            "paused"
          ]
        }
      }
    },
    "LoginCredentials": {
      "type": "object",
      "required": [
        "username",
        "password"
      ],
      "properties": {
        "username": {
          "type": "string",
          "description": "Username for logging in"
        },
        "password": {
          "type": "string",
          "description": "Password for logging in"
        }
      }
    },
    "Session": {
      "type": "object",
      "properties": {
        "token": {
          "type": "string",
          "description": "Session token"
        }
      }
    },
    "UserProfile": {
      "type": "object",
      "properties": {
        "id": {
          "type": "string"
        },
        "name": {
          "type": "string"
        },
        "email": {
          "type": "string"
        },
        "created_at": {
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "Error": {
      "type": "object",
      "required": [
        "code",
        "message"
      ],
      "properties": {
        "code": {
          "type": "integer",
          "format": "int32"
        },
        "message": {
          "type": "string"
        }
      }
    }
  }
}
