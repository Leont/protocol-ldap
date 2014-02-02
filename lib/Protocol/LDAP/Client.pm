package Protocol::LDAP::Client;

use Moo;

with 'Protocol::Role::LDAP';

use Net::LDAP::Async;
use Net::LDAP::ASN qw/LDAPResponse/;
use Net::LDAP::Constant qw/LDAP_SERVER_DOWN/;

use Carp 'croak';

use namespace::clean;

has '+decoder' => (
	default => sub { $LDAPResponse },
);

has _ldap_options => (
	is       => 'ro',
	init_arg => 'ldap_options',
	default  => sub { {} },
);

my @ldap_dn = qw/add bind compare delete moddn modify/;
my @ldap_nodn = qw/search starttls/;
my @ldap_nocb = qw/abandon unbind/;

has on_request => (
	is       => 'ro',
	required => 1,
);

has _ldap => (
	is        => 'lazy',
	predicate => '_has_ldap',
	handles   => [ @ldap_dn, @ldap_nodn, @ldap_nocb ],
	builder   => sub {
		my $self = shift;
		return Net::LDAP::Async->new(%{ $self->_ldap_options}, on_send => $self->on_request);
	},
);

before \@ldap_dn => sub {
	my ($self, $dn, %options) = @_;
	croak 'No callback given' if not $options{callback};
	return;
};

before \@ldap_nodn => sub {
	my ($self, %options) = @_;
	croak 'No callback given' if not $options{callback};
	return;
};

sub on_message {
	my ($self, $response) = @_;
	my $ldap = $self->_ldap;
 
	my $mid = $response->{messageID};
	my $mesg = $ldap->{net_ldap_mesg}{$mid};

	if ($mesg) {
		$mesg->decode($response);
	}
	else {
		if (my $ext = $response->{protocolOp}{extendedResp}) {
			if ($ext->{responseName} eq '1.3.6.1.4.1.1466.20036') {
				#$self->{connection_callback}->( -1, LDAP_SERVER_DOWN, "Notice of Disconnection" );
				 
				if (my $messages = $ldap->{net_ldap_mesg}) {
					foreach my $current (values %$messages) {
						$current->set_error(LDAP_SERVER_DOWN, "Notice of Disconnection");
					}
				}
				$ldap->{net_ldap_mesg} = {};
			} else {
				# error
			}
		}
		else {
			# This should be an error
		}
	}
}

sub DEMOLISH {
	my $self = shift;
	$self->ldap->disconnect if $self->_has_ldap;
	return;
}

1;
