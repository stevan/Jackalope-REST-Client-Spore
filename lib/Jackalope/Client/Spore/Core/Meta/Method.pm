package Jackalope::Client::Spore::Core::Meta::Method;
use Moose;

extends 'Net::HTTP::Spore::Meta::Method';

sub wrap {
    my ( $class, %args ) = @_;

    my $code = sub {
        my ( $self, %method_args ) = @_;

        my $method   = $self->meta->find_spore_method_by_name( $args{name} );
        my $env      = $class->build_env( $self, $method, %method_args );
        my $response = $self->http_request($env);
        my $code     = $response->status;

        my $ok = ($method->has_expected_status)
            ? $method->find_expected_status( sub { $_ eq $code } )
            : $response->is_success;

        die $response if not $ok;

        if ( $response->)

        $response;
    };
    $args{body} = $code;

    $class->Moose::Meta::Method::wrap(%args);
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Client::Sport::Core::Meta::Method;

=head1 DESCRIPTION

