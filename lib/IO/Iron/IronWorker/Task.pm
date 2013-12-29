package IO::Iron::IronWorker::Task;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::IronWorker::Task - IronWorker (worker platform) Client (Task).

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Please see IO::Iron::IronWorker::Client for usage.

=head1 REQUIREMENTS

=cut

use Log::Any  qw($log);
use Hash::Util qw{lock_keys unlock_keys};
use Carp::Assert::More;
use English '-no_match_vars';

# CONSTANTS for this module

# DEFAULTS
#my $DEFAULT_DELAY = 0;
#my $DEFAULT_TIMEOUT = 3600;
#my $DEFAULT_PRIORITY = 0;

=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my ($class, $params) = @_;
	$log->tracef('Entering new(%s, %s)', $class, $params);
	my $self;
	my @self_keys = ( ## no critic (CodeLayout::ProhibitQuotedWordLists)
		'ironworker_client',         # Reference to IronWorker client
		'connection',            # Reference to REST client
		'last_http_status_code', # After successfull network operation, the return value is here.
		# Can be given when queueing a new task:
		'code_name',       # The name of the code package to execute for this task (mandatory).
		'payload',         # A string of data to be passed to the worker (usually JSON), can be empty (mandatory).
		'priority',        # The priority queue to run the task in. Valid values are 0, 1, and 2. 0 is the default.
		'timeout',         # The maximum runtime of your task in seconds.
		'delay',           # The number of seconds to delay before actually queuing the task. Default is 0.
		# These are for scheduled task:
		'run_every',       # The amount of time, in seconds, between runs
		'end_at',          # The time tasks will stop being queued. Should be a time or datetime.
		'run_times',       # The number of times a task will run.
		'start_at',        # The time the scheduled task should first be run.
		# Returned when queried a queued task:
		'id',              # Task or Scheduled task id.
		'project_id',      # Iron.io project ID.
		'code_id',         # The code package id.
		'status',          # Task execution status.
		'code_history_id', # Code package revision id?
		'code_rev',        # Code package revision number.
		'start_time',      # Execution started?
		'end_time',        # Execution finished?
		'duration',        # Execution duration?
		'updated_at',      # Timestamp (ISO) of last update.
		'created_at',      # Timestamp (ISO) of creation. E.g. "2012-11-10T18:31:08.064Z"
		'name',            # Name of task or scheduled task.
	);
	lock_keys(%{$self}, @self_keys);
	$self->{'ironworker_client'} = $params->{'ironworker_client'} if defined $params->{'ironworker_client'};
	$self->{'connection'} = $params->{'connection'} if defined $params->{'connection'};
	assert_isa( $self->{'connection'}, 'IO::Iron::Connection', 'self->{\'connection\'} is IO::Iron::Connection.' );
	assert_isa( $self->{'ironworker_client'}, 'IO::Iron::IronWorker::Client', 'self->{\'ironworker_client\'} is IO::Iron::IronWorker::Client.' );

	$self->{'code_name'} = $params->{'code_name'};
	$self->{'payload'} = $params->{'payload'};
	$self->{'priority'} = $params->{'priority'} if defined $params->{'priority'};
	$self->{'timeout'} = $params->{'timeout'}  if defined $params->{'timeout'};
	$self->{'delay'} = $params->{'delay'} if defined $params->{'delay'};

	$self->{'run_every'} = $params->{'run_every'} if defined $params->{'run_every'};
	$self->{'end_at'} = $params->{'end_at'} if defined $params->{'end_at'};
	$self->{'run_times'} = $params->{'run_times'} if defined $params->{'run_times'};
	$self->{'start_at'} = $params->{'start_at'} if defined $params->{'start_at'};

	$self->{'id'} = $params->{'id'} if defined $params->{'id'};
	$self->{'project_id'} = $params->{'project_id'} if defined $params->{'project_id'};
	$self->{'code_id'} = $params->{'code_id'} if defined $params->{'code_id'};
	$self->{'status'} = $params->{'status'} if defined $params->{'status'};
	$self->{'code_history_id'} = $params->{'code_history_id'} if defined $params->{'code_history_id'};
	$self->{'code_rev'} = $params->{'code_rev'} if defined $params->{'code_rev'};
	$self->{'start_time'} = $params->{'start_time'} if defined $params->{'start_time'};
	$self->{'end_time'} = $params->{'end_time'} if defined $params->{'end_time'};
	$self->{'duration'} = $params->{'duration'} if defined $params->{'duration'};
	$self->{'updated_at'} = $params->{'updated_at'} if defined $params->{'updated_at'};
	$self->{'created_at'} = $params->{'created_at'} if defined $params->{'created_at'};
	$self->{'name'} = $params->{'name'} if defined $params->{'name'};

	# All of the above can be undefined, except the codename and payload.
	assert_nonblank( $self->{'code_name'}, 'code_name is defined and is not blank.' );
	assert_defined( $self->{'payload'}, 'payload is defined, can be blank.' );
	# If priority, timeout or delay are undefined, the IronWorker defaults (at the server) will be used.

	unlock_keys(%{$self});
	my $blessed_ref = bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	$log->tracef('Exiting new: %s', $blessed_ref);
	return $blessed_ref;
}

=head2 id

Set or get id.

=cut

sub id {
	my ($self, $id) = @_;
	$log->tracef('Entering id(%s)', $id);
	if( defined $id ) {
		$self->{'id'} = $id;
		return 1;
	}
	else {
		return $self->{'id'};
	}
}

=head2 log

=over

=item Params: [none]

=item Return: task log (text/plain).

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Return the task's log (task's stdout).

=cut

sub log {
	my ($self) = @_;
	$log->tracef('Entering log().');

	my $task_id = $self->id();
	assert_nonblank($task_id, 'task id not set. Task queued yet?');
	my $connection = $self->{'connection'};
	my ( $http_status_code, $response_message ) =
		$connection->perform_iron_action(
		IO::Iron::IronWorker::Api::IRONWORKER_GET_A_TASKS_LOG(),
		{ '{Task ID}' => $task_id, } );
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef( 'Exiting log(): %s', $response_message );
	return $response_message;
}

=head2 cancel

=over

=item Params: [none]

=item Return: 1 if successful.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Cancel a task.

=cut

sub cancel {
	my ($self) = @_;
	$log->tracef('Entering cancel().');

	my $task_id = $self->id();
	assert_nonblank($task_id, 'task id not set. Task queued yet?');
	my $connection = $self->{'connection'};
	my ( $http_status_code, $response_message ) =
		$connection->perform_iron_action(
		IO::Iron::IronWorker::Api::IRONWORKER_CANCEL_A_TASK(),
		{ '{Task ID}' => $task_id, } );
	$self->{'last_http_status_code'} = $http_status_code;
	assert_is($response_message->{'msg'}, 'Cancelled'); # FIXME Could be dangerous!

	$log->tracef( 'Exiting cancel(): %s', 1 );
	return 1;
}

=head2 set_progress

=over

=item Params (in params hash): percent (integer), msg (free text)

=item Return: 1 if successful.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Set the progress info to the task.

=cut

sub set_progress {
	my ($self, $params) = @_;
	assert_hashref( $params, 'params is not defined or is not a hash reference.');
	assert_nonblank( $params->{'percent'}, 'params->{percent} is not defined or is blank');
	assert_nonblank( $params->{'msg'}, 'params->{msg}  is not defined or is blank');
	$log->tracef('Entering set_progress(%s)', $params);

	my $task_id = $self->id();
	assert_nonblank($task_id, 'task id not set. Task queued yet?');
	my $connection = $self->{'connection'};
	my %request_body;
	$request_body{'percent'} = $params->{'percent'} if defined $params->{'percent'};
	$request_body{'msg'} = $params->{'msg'} if defined $params->{'msg'};
	my ( $http_status_code, $response_message ) = $connection->perform_iron_action(
		IO::Iron::IronWorker::Api::IRONWORKER_SET_A_TASKS_PROGRESS(),
		{ '{Task ID}' => $task_id,
			'body' => \%request_body,
		}
	);
	$self->{'last_http_status_code'} = $http_status_code;
	assert_is($response_message->{'msg'}, 'Progress set'); # FIXME Could be dangerous!

	$log->tracef( 'Exiting set_progress(): %s', 1 );
	return 1;
}

=head2 retry

=over

=item Params: [none]

=item Return: new task id if successful.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Retry a task. A new task id is updated to id field of the object. The id is also returned.

=cut

sub retry {
	my ($self, $delay) = @_;
	assert_nonnegative($delay, 'delay is non-negative integer.');
	$log->tracef( 'Entering retry(%s)', $delay );

	my $task_id = $self->id();
	assert_nonblank($task_id, 'task id not set. Task queued yet?');
	my $connection = $self->{'connection'};
	my %request_body;
	$request_body{'delay'} = $delay;
	my ( $http_status_code, $response_message ) = $connection->perform_iron_action(
		IO::Iron::IronWorker::Api::IRONWORKER_RETRY_A_TASK(),
		{
			'{Task ID}' => $task_id,
			'body' => \%request_body,
		}
	);
	$self->{'last_http_status_code'} = $http_status_code;
	assert_is($response_message->{'msg'}, 'Queued up'); # FIXME Could be dangerous!
	my $new_task_id = $response_message->{'tasks'}->[0]->{'id'};
	$self->id($new_task_id); # We get a new id.

	$log->tracef( 'Exiting retry(): %s', $new_task_id );
	return $new_task_id;
}

=head2 cancel_scheduled

=over

=item Params: [none]

=item Return: 1 if successful.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Cancel a task.

=cut

sub cancel_scheduled {
	my ($self) = @_;
	$log->tracef('Entering cancel_scheduled().');

	my $task_id = $self->id();
	assert_nonblank($task_id, 'task id not set. Task scheduled yet?');
	my $connection = $self->{'connection'};
	my ( $http_status_code, $response_message ) =
		$connection->perform_iron_action(
		IO::Iron::IronWorker::Api::IRONWORKER_CANCEL_A_SCHEDULED_TASK(),
		{ '{Schedule ID}' => $task_id, } );
	$self->{'last_http_status_code'} = $http_status_code;
	assert_is($response_message->{'msg'}, 'Cancelled'); # FIXME Could be dangerous!

	$log->tracef( 'Exiting cancel_scheduled(): %s', 1 );
	return 1;
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronMQ


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


=head1 ACKNOWLEDGMENTS


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

1; # End of IO::Iron::IronWorker::Task