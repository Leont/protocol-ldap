package Net::LDAP::Async;

use strictures;

use parent 'Net::LDAP';

use Carp 'croak';

use namespace::clean;

sub new {
	my ($class, %args) = @_;
	croak 'No sending callback given' if not $args{on_send};
	my $self = $class->SUPER::new(%args, socket => 1, async => 1, scheme => 'callback');
}

sub connect_callback {
	my ($self, $uri, $args) = @_;
	$self->{net_ldap_socket} = $args->{socket};
	$self->{on_send}         = $args->{on_send};
	return;
}

sub async {
	return 1;
}

sub _sendmesg {
	my ($self, $message) = @_;
	my $ret = $self->{on_send}->($message->pdu);
	$self->inner->{net_ldap_mesg}{ $message->mesg_id } = $message if not $message->done;
	return $ret;
}

sub process {
	croak 'Can\'t call process on Net::LDAP::Async';
}

sub data_ready {
	croak 'Can\'t call data_ready on Net::LDAP::Async';
}

1;
