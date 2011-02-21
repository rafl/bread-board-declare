package MooseX::Bread::Board::Meta::Role::Attribute;
use Moose::Role;

use Bread::Board::Types;

use MooseX::Bread::Board::BlockInjection;
use MooseX::Bread::Board::ConstructorInjection;
use MooseX::Bread::Board::Literal;

has class => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_class',
);

has block => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_block',
);

# has_value is already a method
has literal_value => (
    is        => 'ro',
    isa       => 'Str|CodeRef',
    init_arg  => 'value',
    predicate => 'has_literal_value',
);

has lifecycle => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_lifecycle',
);

has dependencies => (
    is        => 'ro',
    isa       => 'Bread::Board::Service::Dependencies',
    coerce    => 1,
    predicate => 'has_dependencies',
);

after attach_to_class => sub {
    my $self = shift;

    my $meta = $self->associated_class;
    my $attr_reader = $self->get_read_method;

    my %params = (
        associated_attribute => $self,
        name                 => $self->name,
        ($self->has_lifecycle
            ? (lifecycle => $self->lifecycle)
            : ()),
        ($self->has_dependencies
            ? (dependencies => $self->dependencies)
            : ()),
    );

    my $service;
    if ($self->has_class) {
        $service = MooseX::Bread::Board::ConstructorInjection->new(
            %params,
            class => $self->class,
        )
    }
    elsif ($self->has_block) {
        $service = MooseX::Bread::Board::BlockInjection->new(
            %params,
            block => $self->block,
        )
    }
    elsif ($self->has_literal_value) {
        $service = MooseX::Bread::Board::Literal->new(
            %params,
            value => $self->literal_value,
        )
    }
    else {
        return;
    }

    $meta->add_service($service);
};

after _process_options => sub {
    my $class = shift;
    my ($name, $opts) = @_;

    return unless exists $opts->{default};
    return unless exists $opts->{class}
               || exists $opts->{block}
               || exists $opts->{value};

    die "default is not valid when Bread::Board service options are set";
};

around get_value => sub {
    my $orig = shift;
    my $self = shift;
    my ($instance) = @_;

    return $self->$orig($instance)
        if $self->has_value($instance);

    my $val = $instance->get_service($self->name)->get;

    $self->verify_against_type_constraint($val, instance => $instance)
        if $self->has_type_constraint;

    if ($self->should_auto_deref) {
        if (ref($val) eq 'ARRAY') {
            return wantarray ? @$val : $val;
        }
        elsif (ref($val) eq 'HASH') {
            return wantarray ? %$val : $val;
        }
        else {
            die 'XXX';
        }
    }
    else {
        return $val;
    }
};

around accessor_metaclass => sub {
    my $orig = shift;
    my $self = shift;

    return Moose::Meta::Class->create_anon_class(
        superclasses => [ $self->$orig(@_) ],
        roles        => [ 'MooseX::Bread::Board::Meta::Role::Accessor' ],
        cache        => 1
    )->name;
};

no Moose::Role;

1;
