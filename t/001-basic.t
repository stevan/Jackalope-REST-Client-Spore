#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use Data::Dumper;

use Jackalope::Client::Spore;

my $client = Jackalope::Client::Spore->discover('http://localhost:3000/');

$client->create( payload => {
    first_name => 'Stevan',
    last_name  => 'Little',
    age        => 38
});

use Data::Dumper; warn Dumper $client->list;

done_testing;