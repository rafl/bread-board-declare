package Bread::Board::Declare::Literal;
use Moose;
# ABSTRACT: subclass of Bread::Board::Literal for Bread::Board::Declare

=head1 DESCRIPTION

This is a custom subclass of L<Bread::Board::Literal> which does the
L<Bread::Board::Declare::Role::Service> role. See those two modules for more
details.

=cut

extends 'Bread::Board::Literal';
with 'Bread::Board::Declare::Role::Service';

__PACKAGE__->meta->make_immutable;
no Moose;

1;
