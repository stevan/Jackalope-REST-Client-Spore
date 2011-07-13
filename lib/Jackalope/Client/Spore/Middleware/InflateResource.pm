package Jackalope::Client::Spore::Middleware::InflateResource;
use Moose;

use Data::Dumper;
use Jackalope::Client::Spore::Resource;

extends 'Net::HTTP::Spore::Middleware';

sub call {
    my ( $self, $req ) = @_;

    return $self->response_cb(
        sub {
            my $res = shift;
            if ( $res->body ) {
                my $body = $res->body;
                if ( ref $body eq 'ARRAY' ) {
                    $res->body([ map { Jackalope::Client::Spore::Resource->new( $_ ) } @$body ]);
                }
                else {
                    $res->body( Jackalope::Client::Spore::Resource->new( $body ) );
                }
            }
        }
    );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Client::Spore::Middleware::InflateResource;

=head1 DESCRIPTION

