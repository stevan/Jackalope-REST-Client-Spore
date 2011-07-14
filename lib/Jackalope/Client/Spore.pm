package Jackalope::Client::Spore;
use Moose;

use Net::HTTP::Spore;
use JSON::XS;

sub discover {
    my ($self, $base_url) = @_;

    # NOTE:
    # we are assuming the
    # describedby link
    # is present. Is that
    # okay? I dunno.
    # - SL

    my $discovery_client = Net::HTTP::Spore->new_from_string(
        JSON::XS->new->encode({
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

    my $data = $discovery_client->describedby->body;

    my $id     = $data->{'id'};
    my $schema = $data->{'body'}->{ $id };

    my $methods = {};
    foreach my $linkrel ( values %{ $schema->{'links'} } ) {
        $methods->{ $linkrel->{'rel'} } = $self->jackalope_linkrel_to_spore_method( $linkrel );
    }

    use Data::Dumper; warn Dumper $methods;

    my $client = Net::HTTP::Spore->new_from_string(
        JSON::XS->new->encode({
            base_url => $base_url,
            version  => '0.01',
            methods  => $methods
        })
    );
    $client->enable('+Jackalope::Client::Spore::Middleware::InflateResource');
    $client->enable('Format::JSON');

    $client;
}

sub jackalope_linkrel_to_spore_method {
    my ($self, $linkrel) = @_;

    my %additional;

    if ( exists $linkrel->{'data_schema'} ) {
        my $data_schema = $linkrel->{'data_schema'};

        if ($linkrel->{'method'} eq 'PUT' || $linkrel->{'method'} eq 'POST') {
            $additional{'header'}           = { 'content-type' => 'application/json' };
            $additional{'required_payload'} = 1;
        }

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

    if ( exists $linkrel->{'uri_schema'} ) {
        my $uri_schema = $linkrel->{'uri_schema'};
        $additional{'required_params'} = [
            keys %$uri_schema
        ];
    }

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

  use Jackalope::Client::Spore;

=head1 DESCRIPTION

