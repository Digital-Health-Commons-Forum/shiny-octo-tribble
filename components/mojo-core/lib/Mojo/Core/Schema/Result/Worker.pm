package Mojo::Core::Schema::Result::Worker;
use DBIx::Class::Candy -autotable => v1;

use warnings;
use strict;
our $VERSION = '0.017';

primary_column id => {
    data_type => 'integer',
    is_auto_increment => 1,
};

column name => {
    data_type => 'text',
    not_null => 1,
};

column status => {
    data_type => 'text',
    not_null => 1,
};

column type_id => {
    data_type => 'integer',
    is_foreign_key => 1,
};

belongs_to type => 'Mojo::Core::Schema::Result::Type', 'type_id';

1;
