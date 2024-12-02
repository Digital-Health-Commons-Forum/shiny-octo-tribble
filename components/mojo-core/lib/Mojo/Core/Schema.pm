package Mojo::Core::Schema;

# ABSTRACT: Primary DBIx::Class schema class for Mojo::Core

use warnings;
use strict;
our $VERSION = '0.022';

use base 'DBIx::Class::Schema';
__PACKAGE__->load_namespaces;

1;
