package Hosting::Default;

use Mojo::Base 'Mojolicious::Controller';

sub dynamic {
    my $self = shift;

    $self->stash(msg => "we are the default");

    my $path = Mojo::Util::class_to_file(__PACKAGE__);

    return($self->render("$path/home"));
}

sub static {
    my $self = shift;

    my $path = Mojo::Util::class_to_file(__PACKAGE__);

    $self->app->log->debug($path);

    return($self->render_static("$path/file.txt"));
}

1;
