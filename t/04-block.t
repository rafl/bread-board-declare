#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;
    use MooseX::Bread::Board;

    has foo => (
        is      => 'ro',
        isa     => 'Str',
        default => 'FOO',
    );

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        value => 'BAR',
    );

    has baz => (
        is           => 'ro',
        isa          => 'Baz',
        block        => sub {
            my ($s, $self) = @_;
            return $s->param('bar') . $self->foo;
        },
        dependencies => ['bar'],
    );
}

{
    my $foo = Foo->new;
    is($foo->baz, 'BARFOO', "self is passed properly");
}

done_testing;
