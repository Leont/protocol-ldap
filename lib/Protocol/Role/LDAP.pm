package Protocol::Role::LDAP;

use Moo::Role;

use Protocol::ASN1;

requires 'on_message';

has decoder => (
	is       => 'ro',
	required => 1,
);

has filter => (
	is      => 'lazy',
	builder => sub {
		my $self = shift;
		return Protocol::ASN1->new(
			decoder    => $self->decoder,
			on_message => sub { $self->on_message(@_) });
	},
	handles  => [ 'push_data' ],
);

1;
