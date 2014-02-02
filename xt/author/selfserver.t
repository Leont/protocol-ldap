#! perl 

use strict;
use warnings;

use Test::More tests => 4;
use Net::LDAP::Server::Test;
use Protocol::LDAP::Client;

my $server = Net::LDAP::Server::Test->new(0, auto_schema => 1);
my $socket = $server->port_is_open;
$socket->blocking(0);

my $protocol = Protocol::LDAP::Client->new(on_request => sub { send $socket, $_[0], 0 or die "Couldn't send: $!" });

my $done = 0;
$protocol->bind("cn=org", anonymous => 1, callback => sub { pass("Got reply to bind") } );
$protocol->add("cn=org", attrs => [ foo => "bar" ], callback => sub { pass("Got reply to add"); });
my $count = 0;
$protocol->search(base => "cn=org", scope => 'base', filter => "(foo=*)", callback => sub { 
	my ($search, $entry) = @_;
	if ($search->done) {
		is($count, 1, 'Finished after one attribute');
		$done = 1;
	}
	else {
		is_deeply([ $entry->attributes ], ['foo'], 'Got a single attribute');
		$count++;
	}
});

alarm 10;
while (!$done) {
	vec(my $rbuf = '', fileno $socket, 1 ) = 1;
	select $rbuf, undef, undef, 2 or last;
	sysread $socket, my $buf, 1024;
	$protocol->push_data($buf) if length $buf;
}

