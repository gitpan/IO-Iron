package common;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Data::UUID;

# Utility routines

sub create_unique_queue_name {
	my $ug                = Data::UUID->new();
	my $uuid1             = $ug->create();
	my $unique_queue_name =
	  'TESTQUEUE_' . substr($ug->to_string($uuid1), 1, 12);

    return $unique_queue_name;
}

sub create_unique_cache_name {
	my $ug                = Data::UUID->new();
	my $uuid1             = $ug->create();
	my $unique_cache_name =
	  'TESTCACHE_' . substr($ug->to_string($uuid1), 1, 12);

    return $unique_cache_name;
}

1;
