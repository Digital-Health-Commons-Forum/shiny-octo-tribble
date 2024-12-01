package Mojo::Core::Schema;

use warnings;
use strict;
our $VERSION = '0.1.3';

use base 'DBIx::Class::Schema';
__PACKAGE__->load_namespaces;

1;
