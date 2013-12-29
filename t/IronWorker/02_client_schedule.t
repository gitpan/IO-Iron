#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Slurp;

use lib 't';
use common;

plan tests => 6;

require IO::Iron::IronWorker::Client;
#require IO::Iron::IronMQ::Message;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 4;

diag("Testing IO::Iron::IronWorker::Client $IO::Iron::IronWorker::Client::VERSION, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronWorker::Client');

my $worker_as_string_rev_01 = <<EOF;
#!/bin/sh
sleep 3
echo "Hello, World!"
EOF
my $worker_as_zip_rev_01;


my $iron_worker_client;
my $unique_code_package_name_01;
my $unique_code_executable_name_01;
my $code_package_id;
subtest 'Setup for testing' => sub {
	plan tests => 1;

	# Create an IronWorker client.
	$iron_worker_client = IO::Iron::IronWorker::Client->new( { 
		'config' => 'iron_worker.json' 
	} );
	
	# Create a new code package name.
	$unique_code_package_name_01 = common::create_unique_code_package_name();
	$unique_code_executable_name_01 = $unique_code_package_name_01 . '.pl';

	my $zip = Archive::Zip->new();
	my $string_member = $zip->addString( $worker_as_string_rev_01, $unique_code_executable_name_01 );
	$string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );

	use IO::String;
	my $io = IO::String->new($worker_as_zip_rev_01);
	{ no warnings 'once';
		tie *IO, 'IO::String';
	}
	$zip->writeToFileHandle($io);

	isnt($worker_as_zip_rev_01, $unique_code_executable_name_01, 'Compressed does not match with uncompressed.');
	diag('Compressed two versions of the worker with zip.');
};

my @send_message_ids;
subtest 'Upload worker and confirm the upload' => sub {
	plan tests => 1;

	# Upload
	my $uploaded_code_id;
	$uploaded_code_id = $iron_worker_client->update_code_package( { 
		'name' => $unique_code_package_name_01,
		'file' => $worker_as_zip_rev_01,
		'file_name' => $unique_code_executable_name_01,
		#'runtime' => 'perl',
		#'runtime' => 'binary',
		'runtime' => 'sh',
	} );
	isnt($uploaded_code_id, undef, 'Code package uploaded.');

	diag("Code package rev 1 uploaded.");
};

subtest 'confirm worker upload' => sub {
	plan tests => 1;

	# And confirm the upload...
	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if($_->{'name'} eq $unique_code_package_name_01) {
			$code_package_id = $_->{'id'};
			last;
		}
	}
	isnt($code_package_id, undef, 'Code package ID retrieved.');

	diag("Code package rev 1 upload confirmed.");
};

subtest 'Queue a task, confirm the creation, cancel it, retry, wait until finished, confirm log' => sub {
	plan tests => 5;

	# queue_task
	my $payload = 'Not used at this point!';
	my $task = $iron_worker_client->create_task(
		$unique_code_package_name_01,
		$payload,
		{
			'run_every' => 120,
			'name' => $unique_code_package_name_01 . '_scheduled_task',
			'run_times' => 5,
			'start_at' => '2030-11-02T21:22:34Z',
		}
	);
	my $ret_task_id = $iron_worker_client->schedule($task);
	my $task_id = $task->id();
	is($ret_task_id, $task_id, 'task object was updated with task id.');

	my $task_info = $iron_worker_client->get_info_about_scheduled_task($task_id);
	is($task_info->{'id'}, $task_id);
	is($task_info->{'status'}, 'scheduled', 'Task is scheduled.');

	# list scheduled tasks
	my $found;
	my @tasks = $iron_worker_client->scheduled_tasks();
	diag('Found ' . scalar @tasks . ' scheduled tasks.');
	foreach (@tasks) {
		if($_->id() eq $task_id) {
			$found = $_->id();
			last;
		}
	}
	isnt($found, undef, 'Code package ID retrieved.');

	# cancel task
	$task->cancel_scheduled();
	$task_info = $iron_worker_client->get_info_about_scheduled_task($task_id);
	is($task_info->{'status'}, 'cancelled', 'Scheduled task is cancelled.');
	diag("Scheduled task is cancelled.");

};

subtest 'Get task results, set progress' => sub {
	plan tests => 3;

	my ($downloaded, $file_name) = $iron_worker_client->download_code_package( 
		$code_package_id, { 
			'revision' => 1,
		} );
	my $zipped_contents = $downloaded;
	is($zipped_contents, $worker_as_zip_rev_01, 'Code package matches the original when zipped.');
	is($file_name, ($unique_code_package_name_01 . '_1.zip'), 'Code package file name matches the original with "_1.zip" suffix.');

	my $downloaded_unzipped;
	my $zip = Archive::Zip->new();
	
	is(1,1,'needless');

	diag("First release downloaded.");
};

subtest 'Clean up.' => sub {
	plan tests => 2;

	my $deleted = $iron_worker_client->delete_code_package( $code_package_id );
	is($deleted, 1, 'Code package deleted.');

	my @code_packages = $iron_worker_client->list_code_packages();
	my $found;
	foreach (@code_packages) {
		if($_->{'name'} eq $unique_code_package_name_01) {
			$found = $_->{'id'};
			last;
		}
	}
	is($found, undef, 'Code package not exists. Delete confirmed.');

	diag("Code package deleted.");
};
