package InfoServant::Index;

use Mojo::Base 'Mojolicious::Controller';

sub slash {
    my $self = shift;

    $self->render(msg => "TODOs abound: " . scalar(localtime(time)));
}

1;

