package IO::Iron;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	use parent qw( Exporter );
	our (@EXPORT_OK, %EXPORT_TAGS);
	%EXPORT_TAGS = ( 'all' => [ qw(ironcache ironmq ironworker) ] );
	@EXPORT_OK   = qw(all ironcache ironmq ironworker);
}
our @EXPORT_OK;

# Global destructor
END {
}

=head1 NAME

IO::Iron - Client Libraries to Iron services IronCache, IronMQ and IronWorker.

=head1 VERSION

Version 0.01_03

=cut

our $VERSION = '0.01_03';

=head1 SYNOPSIS

    use IO::Iron;
    use IO::Iron qw{ironcache ironmq ironworker};
    use IO::Iron ':all';

    my $iron_mq_client = ironmq();
    my @iron_mq_queues = $iron_mq_client->get_queues();

    my $iron_cache_client = ironcache( config => 'iron_cache.json' );
    my @iron_caches = $iron_cache_client->get_caches();


=head1 REQUIREMENTS

The IO::Iron::* packages require the following modules:

=over 8

=item Log::Any, v. 0.15

=item File::Slurp, v. 9999.19

=item JSON, v. 2.53

=item Carp::Assert::More, v. 1.12

=item REST::Client, v. 88

=item File::HomeDir, v. 1.00,

=item Exception::Class, v. 1.37

=item Try::Tiny, v. 0.18

=item URI::Escape, v. 3.31

=back

IO::Iron also requires an IronIO account. Three configuration items must 
be set (others available) before using the functions: 
'project_id', 'token' and 'host'. These can be set in a json file,
as environmental variables or as parameters when creating the object.

=over 8

=item project_id, the identification string, from IronIO.

=item token, an OAuth authentication token string, from IronIO.

=item host, the cloud in which you want to operate: 'cache-aws-us-east-1' for AWS (Amazon).

=back

=cut

# Perl Core
use File::Spec qw{read_file};
use utf8;
use Hash::Util qw{lock_keys unlock_keys};
use Scalar::Util;
use English '-no_match_vars';

# Others
use File::Slurp qw{read_file};
use Log::Any qw{$log};
use JSON;
use File::HomeDir;
use Carp::Assert::More;
use REST::Client;
use URI::Escape;
use Exception::Class;
use Try::Tiny;

require IO::Iron::IronCache::Client;
require IO::Iron::IronMQ::Client;
#require IO::Iron::IronWorker::Client;


=head1 DESCRIPTION

IronCache, IronMQ and IronWorker are cloud based services accessible 
via a REST API. CPAN Distribution IO::Iron contains Perl clients for 
accessing them.

[See L<http://www.iron.io/|http://www.iron.io/>]

Please see the individual clients for further documentation and usage.

Clients:

=over 8

=item L<IO::Iron::IronCache::Client|IO::Iron::IronCache::Client>

=item L<IO::Iron::IronMQ::Client|IO::Iron::IronMQ::Client>

=item L<IO::Iron::IronWorker::Client|IO::Iron::IronWorker::Client>

=back

=head2 IO::Iron

Package IO::Iron is only a "convenience" module for quick startup.
The three functions provided are L<ironcache|/#ironcache>, 
L<ironmq|/#ironmq> and L<ironworker|/#ironworker>.

The following parameters can be given to each of them as hash item type
parameters. See section L<SYNOPSIS|/#SYNOPSIS> for an example.

=over 8

=item project_id,        The ID of the project to use for requests.

=item token,             The OAuth token that is used to authenticate requests.

=item host,              The domain name the API can be located at. E.g. 'mq-aws-us-east-1.iron.io/1'.

=item protocol,          The protocol that will be used to communicate with the API. Defaults to "https".

=item port,              The port to connect to the API through. Defaults to 443.

=item api_version,       The version of the API to connect through. Defaults to the version supported by the client.

=item host_path_prefix,  Path prefix to the RESTful url. Defaults to '/1'. Used with non-standard clouds/emergency service back up addresses.

=item timeout,           REST client timeout (for REST calls accessing IronMQ.)

=item config,            Config filename with path if required.

=back

You can also give the parameters in the config file '.iron.json' or 
'iron.json' (in local dir) or as environmental variables. Please read 
http://dev.iron.io/mq/reference/configuration/ for further details.

=head3 Client Documentation

Please read individual client's documentation for using them.

=cut


# FUNCTIONS

=head2 ironcache

Create an IronCache client object and return it to user.

=cut

sub ironcache {
	my (%params) = @_;
	return IO::Iron::IronCache::Client->new( \%params );
}

=head2 ironmq

Create an IronMQ client object and return it to user.

=cut

sub ironmq {
	my (%params) = @_;
	return IO::Iron::IronMQ::Client->new( \%params );
}

=head2 ironworker

Create an IronWorker client object and return it to user.

=cut

sub ironworker {
	my (%params) = @_;
	croak('IronWorker not yet implemented!');
	#return IO::Iron::IronWorker::Client->new( \%params );
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ironmq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Iron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Iron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Iron>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Iron/>

=back


=head1 ACKNOWLEDGEMENTS

Cool idea, "message queue in the cloud": http://www.iron.io/.
And well implemented, too, with webhooks for several functions!

=head1 TODO

=over 4

=item * Implement IO::Iron::IronWorker.

=item * The IronMQ client needs to control the queues, perhaps using semafores.

=item * A buffer mechanism to keep the messages while the IronMQ REST service is unavailable. IO::Iron::IronMQ::ASyncPush?

=item * Push queues.

=item * Mock IronMQ for testing.

=item * Handle message size (total), delay, timeout and expiration min-max values.

=over 4

=item * Message Var	Default	Maximum	Notes

=item * Message Size	--	64KB	Includes the entire request (delay, timeout, expiration).

=item * Delay	0sec	604,800sec	Message is made available on queue after the delay expires.

=item * Timeout	60sec	86,400sec	Message goes back on queue after timeout unless deleted.

=item * Expiration	604,800sec	2,592,000sec	Equates to 7 days and 30 days, respectively.

=item * Messages per Get	1	100	One or more messages can be handled at a time.

=back

=item * A strategy for log and error messages?

=item * Option to delete queue when IO::Iron::IronMQ::Queue object goes to garbage collection?

=item * Verify the client is connected when created (by calling queues?)

=item * Start using "=encoding utf8" and move compatibility from 5.8 to 5.10.

=item * Rethink the using of REST:Client. Since message queues often involve a lot of traffic 
but always to the same address, REST:Client might not be the best solution.

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mikko Koivunalho.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of IO::Iron
