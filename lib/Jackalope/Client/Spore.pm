package Jackalope::Client::Spore;
use Moose;

use Net::HTTP::Spore;
use JSON::XS;

sub discover {
    my ($self, $base_url) = @_;

    my $discovery_client = Net::HTTP::Spore->new_from_string(
        JSON::XS->new->encode({
            base_url => $base_url,
            version  => '0.01',
            methods  => { describedby => { path => '/', method => 'OPTIONS' } }
        })
    );
    $discovery_client->enable('Format::JSON');

    my $data = $discovery_client->describedby->body;

    my $id     = $data->{'id'};
    my $schema = $data->{'body'}->{ $id };

    my $client = Net::HTTP::Spore->new_from_string(
        JSON::XS->new->encode({
            base_url => $base_url,
            version  => '0.01',
            methods  => {
                map {
                    ($_->{'rel'} => {
                        path   => $_->{'href'},
                        method => $_->{'method'},
                        (exists $_->{'data_schema'} && ($_->{'method'} eq 'PUT' || $_->{'method'} eq 'POST')
                            ? (header => { 'content-type' => 'application/json' })
                            : ())
                    })
                } values %{ $schema->{'links'} }
            }
        })
    );
    $client->enable('+Jackalope::Client::Spore::Middleware::InflateResource');
    $client->enable('Format::JSON');

    $client;
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Client::Spore;

=head1 DESCRIPTION

