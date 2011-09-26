#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;
use Test::TCP;

use Plack::Loader;
use Bread::Board;

use Jackalope::REST;
use Jackalope::REST::Resource::Repository::Simple;
use Jackalope::REST::Client::Spore;

my $j = Jackalope::REST->new;
my $c = container $j => as {

    service 'MySchema' => {
        id         => 'simple/person',
        title      => 'This is a simple person schema',
        extends    => { '__ref__' => 'jackalope/rest/service/crud' },
        properties => {
            first_name => { type => 'string' },
            last_name  => { type => 'string' },
            age        => { type => 'integer', greater_than => 0 },
        }
    };

    typemap 'Jackalope::REST::Resource::Repository::Simple' => infer;

    service 'MyService' => (
        class        => 'Jackalope::REST::CRUD::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'type:Jackalope::REST::Resource::Repository::Simple',
            schema              => 'MySchema',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );
};

my $app = $c->resolve( service => 'MyService' )->to_app;

test_tcp(
    server => sub {
        my $port = shift;
        my $server = Plack::Loader->auto( port => $port, host => '127.0.0.1' );
        $server->run( $app );
    },
    client => sub {
        my $port = shift;

        my $client = Jackalope::REST::Client::Spore->discover('http://127.0.0.1:' . $port . '/');
        isa_ok($client, 'Net::HTTP::Spore::Core');

        {
            my $result;
            is(exception {
                $result = $client->create( payload => {
                    first_name => 'Stevan',
                    last_name  => 'Little',
                    age        => 38
                })
            }, undef, '... created a resource successfully');

            isa_ok($result, 'Net::HTTP::Spore::Response');
            is($result->status, 201, '... got the expected status');

            my $resource = $result->body;
            isa_ok($resource, 'Jackalope::REST::Client::Spore::Resource');

            is($resource->get('first_name'), 'Stevan', '... got the expected data');
            is($resource->get('last_name'), 'Little', '... got the expected data');
            is($resource->get('age'), 38, '... got the expected data');
        }

        {
            my $result;
            is(exception {
                $result = $client->read( id => 1 )
            }, undef, '... get a resource successfully');

            isa_ok($result, 'Net::HTTP::Spore::Response');
            is($result->status, 200, '... got the expected status');

            my $resource = $result->body;
            isa_ok($resource, 'Jackalope::REST::Client::Spore::Resource');

            is($resource->get('first_name'), 'Stevan', '... got the expected data');
            is($resource->get('last_name'), 'Little', '... got the expected data');
            is($resource->get('age'), 38, '... got the expected data');

            $resource->set('age' => 39);

            my $old_version = $resource->version;

            {
                my $result;
                is(exception {
                    $result = $client->edit(
                        id      => $resource->id,
                        payload => $resource->pack
                    );
                }, undef, '... get a resource successfully');

                isa_ok($result, 'Net::HTTP::Spore::Response');
                is($result->status, 202, '... got the expected status');

                my $resource = $result->body;
                isa_ok($resource, 'Jackalope::REST::Client::Spore::Resource');

                is($resource->get('first_name'), 'Stevan', '... got the expected data');
                is($resource->get('last_name'), 'Little', '... got the expected data');
                is($resource->get('age'), 39, '... got the expected data');

                isnt($old_version, $resource->version, '... new version of this resourece');
            }

        }

        {
            my $result;
            is(exception {
                $result = $client->read( id => 1 )
            }, undef, '... get a resource successfully');

            isa_ok($result, 'Net::HTTP::Spore::Response');
            is($result->status, 200, '... got the expected status');

            my $resource = $result->body;
            isa_ok($resource, 'Jackalope::REST::Client::Spore::Resource');

            is($resource->get('first_name'), 'Stevan', '... got the expected data');
            is($resource->get('last_name'), 'Little', '... got the expected data');
            is($resource->get('age'), 39, '... got the expected data');
        }

        is(exception { $client->create }, 'HTTP status: 599', '... payload it required to create a resource');
        is(exception { $client->read   }, 'HTTP status: 599', '... id is required to get a resource');
        is(exception { $client->edit   }, 'HTTP status: 599', '... id is required to edit a resource');
    },
);

done_testing;