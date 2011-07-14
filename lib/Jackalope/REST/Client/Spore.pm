package Jackalope::REST::Client::Spore;
use Moose;

use Jackalope::Util qw[ encode_json ];
use Net::HTTP::Spore;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub discover {
    my ($self, $base_url) = @_;

    # NOTE:
    # we are assuming the
    # describedby link
    # is present. Is that
    # okay? I dunno.
    # - SL

    my $discovery_client = Net::HTTP::Spore->new_from_string(
        encode_json({
            base_url => $base_url,
            version  => '0.01',
            methods  => {
                describedby => {
                    path            => '/',
                    method          => 'OPTIONS',
                    expected_status => [ 200 ]
                }
            }
        })
    );
    $discovery_client->enable('Format::JSON');

    # TODO:
    # if we start using custom content-types
    # in Jackalope, we should make a note of
    # the content type returned by this initial
    # discovery action since it will be likely
    # exactly what we will get in the other
    # methods.
    # - SL

    my $data = $discovery_client->describedby->body;

    my $id     = $data->{'id'};
    my $schema = $data->{'body'}->{ $id };

    my $methods = {};
    foreach my $linkrel ( values %{ $schema->{'links'} } ) {
        $methods->{ $linkrel->{'rel'} } = $self->jackalope_linkrel_to_spore_method( $linkrel );
    }

    my $client = Net::HTTP::Spore->new_from_string(
        encode_json({
            base_url => $base_url,
            version  => '0.01',
            methods  => $methods
        })
    );
    $client->enable('+Jackalope::REST::Client::Spore::Middleware::InflateResource');
    $client->enable('Format::JSON');

    $client;
}

sub jackalope_linkrel_to_spore_method {
    my ($self, $linkrel) = @_;

    # NOTE:
    # We make some assumptions here
    # based on the opinions found in
    # Jackalope::REST::CRUD services
    # and general Jackalope::REST
    # usage. These assumptions are
    # detailed below.
    # - SL

    my %additional;

    if ( exists $linkrel->{'data_schema'} ) {
        my $data_schema = $linkrel->{'data_schema'};

        # ASSUMPTION:
        # PUT and POST are typically
        # for 'update' and 'create'
        # so we can expect them to
        # have a payload and for it
        # to have the expected
        # content-type as well.
        if ($linkrel->{'method'} eq 'PUT' || $linkrel->{'method'} eq 'POST') {
            $additional{'header'}           = { 'content-type' => 'application/json' };
            $additional{'required_payload'} = 1;
        }

        # ASSUMPTION:
        # If we have a GET and some
        # data_schema items then we
        # can assume that these are
        # required/optional params
        # based on the data_schema
        if ($linkrel->{'method'} eq 'GET') {

            if ( exists $data_schema->{'properties'} ) {
                $additional{'required_params'} = [
                    keys %{ $data_schema->{'properties'} }
                ];
            }

            if ( exists $data_schema->{'additional_properties'} ) {
                $additional{'optional_params'} = [
                    keys %{ $data_schema->{'additional_properties'} }
                ];
            }

        }
    }

    # ASSUMPTION
    # A uri_schema will alert
    # us to the need to have
    # come required params for
    # the URI template
    if ( exists $linkrel->{'uri_schema'} ) {
        my $uri_schema = $linkrel->{'uri_schema'};
        $additional{'required_params'} = [
            keys %$uri_schema
        ];
    }

    # ASSUMPTION
    # these are assumptions that we
    # make based on the default behaviors
    # that are in Jackalope::REST::CRUD
    # target classes, this might be going
    # to far, but honestly this is a
    # pretty sane set of defaults to go by.
    $additional{'expected_status'} = [ 200 ] if $linkrel->{'method'} eq 'GET' || $linkrel->{'method'} eq 'OPTIONS';
    $additional{'expected_status'} = [ 201 ] if $linkrel->{'method'} eq 'POST';
    $additional{'expected_status'} = [ 202 ] if $linkrel->{'method'} eq 'PUT';
    $additional{'expected_status'} = [ 204 ] if $linkrel->{'method'} eq 'DELETE';

    return +{
        path   => $linkrel->{'href'},
        method => $linkrel->{'method'},
        %additional
    }
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Client::Spore;

=head1 DESCRIPTION

