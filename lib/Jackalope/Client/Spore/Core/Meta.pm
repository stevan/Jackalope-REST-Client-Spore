package Jackalope::Client::Spore::Core::Meta;
use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

Moose::Exporter->setup_import_methods( also => [qw[ Moose ]] );

sub init_meta {
    my ($class, %options) = @_;

    my $for = $options{for_class};
    Moose->init_meta(%options);

    my $meta = Moose::Util::MetaRole::apply_metaroles(
        for       => $for,
        class_metaroles => {
            class => ['Jackalope::Client::Spore::Core::Meta::Class'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $for,
        roles => [
            qw/
              Net::HTTP::Spore::Role::Debug
              Net::HTTP::Spore::Role::Description
              Net::HTTP::Spore::Role::UserAgent
              Net::HTTP::Spore::Role::Request
              Net::HTTP::Spore::Role::Middleware
              /
        ],
    );

    $meta;
};

1;
