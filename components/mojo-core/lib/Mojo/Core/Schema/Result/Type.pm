package Mojo::Core::Schema::Result::Type;
use DBIx::Class::Candy -autotable => v1;

use warnings;
use strict;
our $VERSION = '0.021';

primary_column id => {
    data_type => 'integer',
    is_auto_increment => 1,
};

column name => {
    data_type => 'text',
    not_null => 1,
};

column type_id => {
    data_type => 'integer',
    not_null => 1,
};

1;
