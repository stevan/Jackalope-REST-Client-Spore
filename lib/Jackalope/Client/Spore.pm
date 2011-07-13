package Jackalope::Client::Spore;
use Moose;

use Net::HTTP::Spore;
use JSON::XS;

use Jackalope::Client::Spore::Core;

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

    my $spore_class = Class::MOP::Class->create_anon_class(
        superclasses => ['Jackalope::Client::Spore::Core']
    );

    my $client = $spore_class->new_object({
        base_url => $base_url,
        version  => '0.01',
    });

    foreach my $link ( values %{ $schema->{'links'} } ) {

        my %additional;

        if (exists $_->{'data_schema'} && ($_->{'method'} eq 'PUT' || $_->{'method'} eq 'POST')) {
            $additional{'header'} = {
                'Content-Type' => 'application/json'
            };
        }

        $spore_class->add_spore_method(
            $link->{'rel'} => (
                path   => $link->{'href'},
                method => $link->{'method'},
                %additional
            )
        );
    }

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

