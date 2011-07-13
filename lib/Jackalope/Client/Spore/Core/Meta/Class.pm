package Jackalope::Client::Spore::Core::Meta::Class;
use Moose::Role;

with 'Jackalope::Client::Spore::Core::Meta::Method::Spore',
     'Net::HTTP::Spore::Role::Debug';

no Moose::Role; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Client::Sport::Core::Meta::Class;

=head1 DESCRIPTION

