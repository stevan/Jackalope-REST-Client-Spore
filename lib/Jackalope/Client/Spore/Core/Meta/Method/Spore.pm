package Jackalope::Client::Spore::Core::Meta::Method::Spore;
use Moose::Role;

use Jackalope::Client::Spore::Core::Meta::Method;

with 'Net::HTTP::Spore::Meta::Method::Spore';

sub method_metaclass_name { 'Jackalope::Client::Spore::Core::Meta::Method' }

no Moose::Role; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Net::HTTP::Spore::Meta::Method::Spore;

=head1 DESCRIPTION
