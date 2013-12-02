use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME           => 'IO::Iron',
	AUTHOR         => q{Mikko Koivunalho <mikko.koivunalho@iki.fi>},
	VERSION_FROM   => 'lib/IO/Iron.pm',
	ABSTRACT_FROM  => 'lib/IO/Iron.pm',
	LICENSE        => 'Artistic_2_0',
	PL_FILES       => {},
	MIN_PERL_VERSION => 5.006002, # Log::Any
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 0,
	},
	BUILD_REQUIRES => {
		'Test::More' => 0,
		'Log::Any::Test' => 0.15,
		'File::Remove' => 1.52,
		'File::Copy' => 2.21,
		'YAML::Tiny' => 1.51,
		'Test::Exception' => 0.31,
		'IO::Compress::Zip' => 2.060,
		'IO::Uncompress::Unzip' => 2.060,
	},  # FIXME Test::Manifest? Do we need it? looks in the t/test_manifest file to find out which tests you want to run and the order in which you want to run them.
	PREREQ_PM => {
		'Log::Any' => 0.15,
		'File::Slurp' => 9999.19,
		'JSON' => 2.53,
		'use Data::UUID' => 1.219,
		'MIME::Base64' => 3.13,
		'File::Spec' => 0, # Core
		'Hash::Util' => 0, # Core
		'Carp::Assert' => 0.20,
		'Carp::Assert::More' => 1.12,
		'Carp' => 1.26, # Core
		'English' => 0, # Core
		'REST::Client' => 88,
		'File::HomeDir' => 1.00,
		'Exception::Class' => 1.37,
		'Try::Tiny' => 0.18,
		'Scalar::Util' => 1.27,
		'URI::Escape' => 3.31,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'IO-Iron-*' },
);
