package Protocol::ASN1;

use Moo;

use Convert::ASN1 qw/asn_decode_tag asn_decode_length/;

use namespace::clean;

has decoder => (
	is       => 'ro',
	required => 1,
);

has on_message => (
	is       => 'ro',
	required => 1,
);

has buffer => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { return \(my $buf = '') },
);

sub push_data {
	my ($self, $data) = @_;

	my $buffer = $self->buffer;
	${$buffer} .= $data;
	my @blocks;

	while (1) {
		my ($tb, $tag) = asn_decode_tag(${$buffer}) or last;
		my ($lb, $len) = asn_decode_length(substr ${$buffer}, $tb, 8) or last;
		my $length = $tb + $lb + $len;

		if ($length <= length ${$buffer}) {
			my $message = substr ${$buffer}, 0, $length, '';
			my $decoded = $self->decoder->decode($message);
			$self->on_message->($decoded);
		}
		else {
			last;
		}
	}
	return;
}

1;
