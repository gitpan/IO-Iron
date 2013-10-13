package IO::Iron::IronCache::Item;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	# No exports
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::IronCache::Item

=head1 VERSION

Version 0.01_03

=cut

our $VERSION = '0.01_03';


=head1 SYNOPSIS

Please see IO::Iron::IronCache::Client for usage.

=head1 REQUIREMENTS

=cut

use Log::Any  qw($log);
use utf8;
use Hash::Util qw{lock_keys unlock_keys};
use Carp::Assert::More;
use English '-no_match_vars';

# CONSTANTS for this module

# DEFAULTS

=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my ($class, $params) = @_;
	$log->tracef('Entering new(%s, %s)', $class, $params);
	my $self;
	my @self_keys = ( ## no critic (CodeLayout::ProhibitQuotedWordLists)
			'value',        # Item value (free text), can be empty.
			'expires_in',   # How long in seconds to keep the item in the cache before it is deleted.
			'replace',      # Only set the item if the item is already in the cache.
			'add',          # Only set the item if the item is not already in the cache.
			'cas',          # Cas value can only be set when the item is read from the cache.
	);
	lock_keys(%{$self}, @self_keys);
	$self->{'value'} = defined $params->{'value'} ? $params->{'value'} : undef;
	$self->{'expires_in'} = defined $params->{'expires_in'} ? $params->{'expires_in'} : undef;
	$self->{'replace'} = defined $params->{'replace'} ? $params->{'replace'} : undef;
	$self->{'add'} = defined $params->{'add'} ? $params->{'add'} : undef;
	$self->{'cas'} = defined $params->{'cas'} ? $params->{'cas'} : undef;
	# All of the above can be undefined, except the value.
	assert_defined( $self->{'value'}, 'self->{value} is defined and is not blank.' );
	# If timeout, add or expires_in are undefined, the IronMQ defaults (at the server) will be used.

	unlock_keys(%{$self});
	my $blessed_ref = bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	$log->tracef('Exiting new: %s', $blessed_ref);
	return $blessed_ref;
}

=head2 value

Set or get value.

=cut

sub value {
	my ($self, $value) = @_;
	$log->tracef('Entering value()');
	if( defined $value ) {
		$self->{'value'} = $value;
		return 1;
	}
	else {
		return $self->{'value'};
	}
}

#sub value { defined $_[1] ? $_[0]->{'value'} = $_[1], 1 : $_[0]->{'value'}; }

=head2 expires_in

Set or get expires_in.

=cut

sub expires_in {
	my ($self, $expires_in) = @_;
	$log->tracef('Entering expires_in()');
	if( defined $expires_in ) {
		$self->{'expires_in'} = $expires_in;
		return 1;
	}
	else {
		return $self->{'expires_in'};
	}
}

=head2 replace

Set or get replace.

=cut

sub replace {
	my ($self, $replace) = @_;
	$log->tracef('Entering timeout()');
	if( defined $replace ) {
		$self->{'replace'} = $replace;
		return 1;
	}
	else {
		return $self->{'replace'};
	}
}

=head2 add

Set or get add.

=cut

sub add {
	my ($self, $add) = @_;
	$log->tracef('Entering add()');
	if( defined $add ) {
		$self->{'add'} = $add;
		return 1;
	}
	else {
		return $self->{'add'};
	}
}

=head2 cas

Set or get cas.

=cut

sub cas {
	my ($self, $cas) = @_;
	$log->tracef('Entering cas()');
	if( defined $cas ) {
		$self->{'cas'} = $cas;
		return 1;
	}
	else {
		return $self->{'cas'};
	}
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ironmq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronCache::Client


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

1; # End of IO::Iron::IronCache::Item
