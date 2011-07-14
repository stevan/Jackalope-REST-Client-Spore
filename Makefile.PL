use strict;
use warnings;
use inc::Module::Install;

name 'Jackalope-REST-Client-Spore';
all_from 'lib/Jackalope/REST/Client/Spore.pm';
license 'perl';

requires 'Jackalope::REST'  => 0;
requires 'Net::HTTP::Spore' => 0;

build_requires 'Test::More'  => 0;
build_requires 'Test::Moose' => 0;
build_requires 'Test::Fatal' => 0;
build_requires 'Test::TCP'   => 0;

tests('t/*.t');

WriteAll();