package IO::Iron::IronWorker::Client;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	use parent qw( IO::Iron::ClientBase ); # Inheritance
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::IronWorker::Client - IronWorker Client.

=head1 VERSION

Version 0.01_04

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

	require IO::Iron::IronWorker::Client;

	my $ironworker_client = IO::Iron::IronWorker::Client->new( {} );
	# or
	use IO::Iron qw(get_ironworker);
	my $ironworker_client = get_ironworker();

	my $unique_code_package_name = 'HelloWorldCode';
	my $worker_as_zip; # Zipped Perl script and dependencies.
	my $unique_code_executable_file_name = 'HelloWorldCode.pl';
	my $uploaded = $iron_worker_client->update_code_package( { 
		'name' => $unique_code_package_name, 
		'file' => $worker_as_zip, 
		'file_name' => $unique_code_executable_file_name, 
		'runtime' => 'perl', 
	} );

	my $code_package_id;
	my @code_packages = $iron_worker_client->list_code_packages( { } );
	foreach (@code_packages) {
		if($_->{'name'} eq $unique_code_package_name) {
			$code_package_id = $_->{'id'};
			last;
		}
	}

	my $code_package = $iron_worker_client->get_info_about_code_package( $code_package_id );

	my @code_package_revisions = $iron_worker_client->list_code_package_revisions( $code_package_id );

	my $downloaded = $iron_worker_client->download_code_package( 
		$code_package_id, { 
			'revision' => 1,
		} );

	my $delete_rval = $iron_wkr_queue->delete( $code_package_id );


=head1 REQUIREMENTS

Requires the following packages:

=over 8

=item Log::Any, v. 0.15

=item File::Slurp, v. 9999.19

=item JSON, v. 2.53

=item Carp::Assert::More, v. 1.12

=item REST::Client, v. 88

=item File::HomeDir, v. 1.00,

=item Exception::Class, v. 1.37

=item Try::Tiny, v. 0.18

=item Scalar::Util, v. 1.27

=back

Requires IronIO account. Three configuration items must be set (others available) before using the functions: 'project_id', 'token' and 'host'.
These can be set in a json file, as environmental variables or as parameters when creating the object.

=over 8

=item project_id, the identification string, from IronIO.

=item token, an OAuth authentication token string, from IronIO.

=item host, the cloud in which you want to operate: 'worker-aws-us-east-1' for AWS (Amazon).

=back

=cut

#use File::Slurp qw{read_file};
use Log::Any  qw{$log};
#use File::Spec qw{read_file};
#use File::HomeDir;
use Hash::Util qw{lock_keys lock_keys_plus unlock_keys legal_keys};
use Carp::Assert::More;
use English '-no_match_vars';

require IO::Iron::IronWorker::Api;
require IO::Iron::Common;
require IO::Iron::Connection;

# CONSTANTS for this package

# DEFAULTS


=head1 DESCRIPTION

IO::Iron::IronWorker is a client for the IronWorker remote worker system at L<http://www.iron.io/|http://www.iron.io/>.
IronWorker is a cloud based parallel multi-language worker platform. with a REST API.
IO::Iron::IronWorker creates a Perl object for interacting with IronWorker.
All IronWorker functions are available.

The class IO::Iron::IronWorker::Client instantiates the 'project', IronWorker access configuration.

=head2 IronWorker Cloud Parallel Workers

L<http://www.iron.io/|http://www.iron.io/>

IronWorker is a parallel worker platform delivered as a service to Internet connecting 
applications via its REST interface. Built with distributed 
cloud applications in mind, it provides on-demand scalability for workers, 
controls with HTTPS transport and cloud-optimized performance. [see L<http://www.iron.io/|http://www.iron.io/>]

=head2 Using the IronWorker Client Library

IO::Iron::IronWorker::Client is a normal Perl package meant to be used as an object.

    require IO::Iron::IronWorker::Client;
    my $ironworker_client = IO::Iron::IronWorker::Client->new( { } );

The following parameters can be given to new() as items in the first parameter which is a hash.

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

You can also give the parameters in the config file '.iron.json'
(in home dir) or 
'iron.json' (in current dir) or as environmental variables. Please read 
L<http://dev.iron.io/mq/reference/configuration/|http://dev.iron.io/mq/reference/configuration/>
for further details.

After creating the client three sets of commands is available:

=over 8

=item Commands for operating code packages: 

=over 8

=item list_code_packages()

=item update_code_package(params)

=item get_info_about_code_package(code_package_id)

=item delete_code_package(code_package_id)

=item download_code_package(code_package_id, params)

=item list_code_package_revisions(code_package_id)

=back

=item Commands for operating tasks: (NOT YET IMPLEMENTED)

=over 8

=item queue_task

=item get_info_about_task

=item list_tasks

=item get_tasks_log

=item set_tasks_progress

=item retry_task

=item cancel_task

=back

=item Commands for operating scheduled tasks: (NOT YET IMPLEMENTED)

=over 8

=item list_scheduled_tasks

=item schedule_task

=item get_info_about_scheduled_task

=item cancel_scheduled_task

=back

=back

=head3 Operating code packages

A code package is simply a script program packed into Zip archive together 
with its dependency files (other libraries, configuration files, etc.).

After creating the zip file and reading it into a perl variable, upload it.
In the following example, the worker contains only one file
and we create the archive in the program.

	require IO::Iron::IronWorker::Client;
	use IO::Compress::Zip;
	
	$iron_worker_client = IO::Iron::IronWorker::Client->new( { 
		'config' => 'iron_worker.json' 
	} );

	my $worker_as_string_ = <<EOF;
	print qq{Hello, World!\n};
	EOF
	my $worker_as_zip;
	my $worker_
	
	IO::Compress::Zip::zip(\$worker_as_string => \$worker_as_zip);
	
	my $code_package_return_id = $iron_worker_client->update_code_package( { 
		'name' => 'HelloWorld_code_package', 
		'file' => $worker_as_string, 
		'file_name' => helloworld.pl, 
		'runtime' => 'perl', 
	} );

With method list_code_packages() you can retrive information about all 
the uploaded code packages. The method get_info_about_code_package()
will return information about only the requested code package.

	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if($_->{'name'} eq 'HelloWorld_code_package) {
			$code_package_id = $_->{'id'};
			last;
		}
	}
	my $code_package = $iron_worker_client->get_info_about_code_package( $code_package_id );

Method delete_code_package() removes the code package from IronWorker service.

	my $deleted = $iron_worker_client->delete_code_package( $code_package_id );

The uploaded code package can be retrived with method download_code_package().
The downloaded file is a zip archive.

	my $downloaded = $iron_worker_client->download_code_package( 
		$code_package_id, { 
			'revision' => 1,
		} );

The code packages get revision numbers according to their upload order.
The first upload of a code package gets revision number 1. Any subsequent 
upload of the same code package (same name) will get one higher 
revision number so the different uploads can be recognized.

	my @code_package_revisions = $iron_worker_client->list_code_package_revisions( $code_package_id );

=head3 Operating tasks: (NOT YET IMPLEMENTED)

=head3 Operating scheduled tasks: (NOT YET IMPLEMENTED)

=head3 Exceptions

A REST call to IronWorker server may fail for several reason.
All failures generate an exception using the L<Exception::Class|Exception::Class> package.
Class IronHTTPCallException contains the field status_code, response_message and error.
Error is formatted as such: IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>.

	use Try::Tiny;
	use Scalar::Util qw{blessed};
	try {
		my $queried_iron_mq_queue_01 = $iron_mq_client->get_queue($unique_queue_name_01);
	}
	catch {
		die $_ unless blessed $_ && $_->can('rethrow');
		if ( $_->isa('IronHTTPCallException') ) {
			if ($_->status_code == 404) {
				print "Bad things! Can not just find the catch in this!\n";
			}
		}
		else {
			$_->rethrow; # Push the error upwards.
		}
	};


=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my ($class, $params) = @_;
	$log->tracef('Entering new(%s, %s)', $class, $params);
	my $self = IO::Iron::ClientBase->new();
	# Add more keys to the self hash.
	my @self_keys = (
			#'queues',        # References to all objects created of class IO::Iron::IronMQ::Queue.
			legal_keys(%{$self}),
	);
	unlock_keys(%{$self});
	lock_keys_plus(%{$self}, @self_keys);
	my $config = IO::Iron::Common::get_config($params);
	$log->debugf('The config: %s', $config);
	$self->{'project_id'} = defined $config->{'project_id'} ? $config->{'project_id'} : undef;
	#$self->{'queues'} = [];
	assert_nonblank( $self->{'project_id'}, 'self->{project_id} is not defined or is blank');

	unlock_keys(%{$self});
	bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	# Set up the connection client
	my $connection = IO::Iron::Connection->new( {
		'project_id' => $config->{'project_id'},
		'token' => $config->{'token'},
		'host' => $config->{'host'},
		'protocol' => $config->{'protocol'},
		'port' => $config->{'port'},
		'api_version' => $config->{'api_version'},
		'host_path_prefix' => $config->{'host_path_prefix'},
		'timeout' => $config->{'timeout'},
		'connector' => $params->{'connector'},
		}
	);
	$self->{'connection'} = $connection;
	$log->debugf('IronWorker Connection created with config: (project_id=%s; token=%s; host=%s; timeout=%s).', $config->{'project_id'}, $config->{'token'}, $config->{'host'}, $config->{'timeout'});
	$log->tracef('Exiting new: %s', $self);
	return $self;
}

=head2 list_code_packages

Return a list of hashes containing information about every code package in IronWorker.

=over 8

=item Params: [None]

=item Return: List of hashes.

=back

=cut

sub list_code_packages {
	my ($self) = @_;
	$log->tracef('Entering list_code_packages()');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_LIST_CODE_PACKAGES(), { } );
	$self->{'last_http_status_code'} = $http_status_code;
	my @codes;
	foreach (@{$response_message}) {
		push @codes, $_;
	}
	$log->debugf('Returning %d code packages.', scalar @codes);
	$log->tracef('Exiting list_code_packages: %s', \@codes);
	return @codes;
}

=head2 update_code_package

Update an IronWorker code package.

=over 8

=item Params: .

=item Return: new code package id == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

# TODO Clean the function.

sub update_code_package {
	my ($self, $params) = @_;
	$log->tracef('Entering update_code_package(%s)', $params);
	assert_nonblank( $params->{'file'}, 'code package name (params->{file}) is not defined or is blank');

	my $connection = $self->{'connection'};
	my %message_body;
	$message_body{'file'} = $params->{'file'} if defined $params->{'file'};
	$message_body{'file_name'} = $params->{'file_name'} if defined $params->{'file_name'};
	$message_body{'name'} = $params->{'name'} if defined $params->{'name'}; # Code package name.
	$message_body{'runtime'} = $params->{'runtime'} if defined $params->{'runtime'};
	$message_body{'config'} = $params->{'config'} if defined $params->{'config'};
	$message_body{'max_concurrency'} = $params->{'max_concurrency'} if defined $params->{'max_concurrency'};
	$message_body{'retries'} = $params->{'retries'} if defined $params->{'retries'};
	$message_body{'retries_delay'} = $params->{'retries_delay'} if defined $params->{'retries_delay'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_UPLOAD_OR_UPDATE_A_CODE_PACKAGE(),
			{
				'body'         => \%message_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $id = $response_message->{'id'};
	$log->tracef('Exiting update_code_package: %s', $id);
	return $id;
}

=head2 get_info_about_code_package

=over 8

=item Params: code package id.

=item Return: a hash containing info about code package. Exception if code packages does not exist.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub get_info_about_code_package {
	my ($self, $code_package_id) = @_;
	$log->tracef('Entering get_info_about_code_package(%s)', $code_package_id);
	assert_nonblank( $code_package_id, 'code_package_id is not defined or is blank');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_GET_INFO_ABOUT_A_CODE_PACKAGE(),
			{ '{Code ID}' => $code_package_id, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $info = $response_message;
	# Sample:
	#{
	#    "id": "4eb1b241cddb13606500000b",
	#    "project_id": "4eb1b240cddb13606500000a",
	#    "name": "MyWorker",
	#    "runtime": "ruby",
	#    "latest_checksum": "a0702e9e9a84b758850d19ddd997cf4a",
	#    "rev": 1,
	#    "latest_history_id": "4eb1b241cddb13606500000c",
	#    "latest_change": 1328737460598000000
	#}
	$log->tracef('Exiting get_info_about_code_package: %s', $info);
	return $info;
}

=head2 delete_code_package

Delete an IronWorker code package.

=over 8

=item Params: code package id. Code package must exist. If not, fails with an exception.

=item Return: 1 == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub delete_code_package {
	my ($self, $code_package_id) = @_;
	$log->tracef('Entering delete_code_package(%s)', $code_package_id);
	assert_nonblank( $code_package_id, 'code_package_id is not defined or is blank');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_DELETE_A_CODE_PACKAGE(),
			{
				'{Code ID}' => $code_package_id,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	$log->tracef('Exiting delete_code_package: %d', 1);
	return 1;
}

=head2 download_code_package

Download an IronWorker code package.

=over 8

=item Params: code package id. Code package must exist. If not, fails with an exception.
subparam: revision.

=item Return: the code package zipped.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub download_code_package {
	my ($self, $code_package_id, $params) = @_;
	$log->tracef('Entering download_code_package(%s, %s)', $code_package_id, $params);
	assert_nonblank( $code_package_id, 'code_package_id is not defined or is blank');

	my $connection = $self->{'connection'};
	my %query_params;
	$query_params{'{revision}'} = $params->{'revision'} if $params->{'revision'}; ## no critic (ControlStructures::ProhibitPostfixControls)
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_DOWNLOAD_A_CODE_PACKAGE(),
			{
				'{Code ID}' => $code_package_id,
				%query_params,
			}
		);
	my $code_package = $response_message->{'file'};
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting download_code_package: %s', $code_package);
	return $code_package;
}

=head2 list_code_package_revisions

Return a list of hashes containing information about one code package revisions.

=over 8

=item Params: code package id. Code package must exist. If not, fails with an exception.

=item Return: List of hashes.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub list_code_package_revisions {
	my ($self, $code_package_id) = @_;
	$log->tracef('Entering list_code_package_revisions(%s)', $code_package_id);
	assert_nonblank( $code_package_id, 'code_package_id is not defined or is blank');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_LIST_CODE_PACKAGE_REVISIONS(),
			{ '{Code ID}' => $code_package_id, }
		);
	my @revisions;
	foreach (@{$response_message}) {
		push @revisions, $_;
	}
	$log->debugf('Returning %d code packages.', scalar @revisions);
	$log->tracef('Exiting list_code_package_revisions: %s', \@revisions);
	return @revisions;
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronWorker::Client


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

Cool idea, "workers in the cloud": http://www.iron.io/.


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

1; # End of IO::Iron::IronWorker::Client
