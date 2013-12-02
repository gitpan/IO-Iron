#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron;
require IO::Iron::IronWorker::Client;

#plan tests => 27;
plan tests => 8;

BEGIN {
	use_ok('IO::Iron::IronWorker::Client') || print "Bail out!\n";
	can_ok('IO::Iron::IronWorker::Client', 'new');
	can_ok('IO::Iron::IronWorker::Client', 'list_code_packages');
	can_ok('IO::Iron::IronWorker::Client', 'update_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'get_info_about_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'delete_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'download_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'list_code_package_revisions');

}

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

diag("Testing IO::Iron $IO::Iron::VERSION, Perl $], $^X");

if(! -e File::Spec->catfile(File::HomeDir->my_home, '.iron.json') 
		&& ! defined $ENV{'IRON_PROJECT_ID'}
		&& ! -e File::Spec->catfile(File::Spec->curdir(), 'iron.json')) {
	BAIL_OUT("NO IRONMQ CONFIGURATION FILE OR ENV VARIABLE IN PLACE! CANNOT CONTINUE!");
}

###BAIL_OUT("STOP TESTING HERE!");

