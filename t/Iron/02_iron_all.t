#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use lib 't';
use common;

plan tests => 2;

use IO::Iron ':all';

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
#use Data::Dumper; $Data::Dumper::Maxdepth = 1;

diag("Testing IO::Iron::IronMQ::Client $IO::Iron::IronMQ::Client::VERSION, Perl $], $^X");

my $iron_mq_client = ironmq( 'config' => 'iron_mq.json' );
my @iron_mq_queues = $iron_mq_client->get_queues();
ok(scalar @iron_mq_queues >= 0, 'get_queues() returned a list');

my $iron_cache_client = ironcache( 'config' => 'iron_cache.json' );
my @iron_caches = $iron_cache_client->get_caches();
ok(scalar @iron_mq_queues >= 0, 'get_caches() returned a list');
