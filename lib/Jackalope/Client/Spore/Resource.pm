package Jackalope::Client::Spore::Resource;
use Moose;

use Scalar::Util 'looks_like_number';

extends 'Jackalope::REST::Resource';

sub set {
    my ($self, $path, $value) = @_;

    my @parts   = split /\./ => $path;
    my $final   = pop @parts;
    my $current = $self->body;

    foreach my $i ( 0 .. $#parts ) {
        my $part = $parts[ $i ];

        if ( ref $current eq 'HASH' ) {
            $current = $current->{ $part };
        }
        elsif ( ref $current eq 'ARRAY' ) {
            ( looks_like_number $part )
                || confess "Current item is an ARRAY ($current) but current path part is not a number ($part)";
            $current = $current->[ $part ];
        }

        # NOTE:
        # if we still have parts, and
        # this is not a HASH then we
        # have issues.
        # - SL
        confess "Current item is not a HASH or ARRAY ref (" .(defined $current ? $current : 'undef'). ") and there is still path to traverse ("
              . (join "/" => @parts[ $i .. $#parts ]) . ")"
                  if ( $i < $#parts && not( ref $current eq 'HASH' || ref $current eq 'ARRAY' ) );

    }

    if ( ref $current eq 'HASH' ) {
        $current->{ $final } = $value;
    }
    elsif ( ref $current eq 'ARRAY' ) {
        ( looks_like_number $final )
            || confess "Current item is an ARRAY ($current) but current path part is not a number ($final)";
        $current->[ $final ] = $value;
    }

}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Client::Spore::Resource;

=head1 DESCRIPTION

