package InfoServant::Index;

use Mojo::Base 'Mojolicious::Controller';

use SiteCode::Exception;
use SiteCode::Account;

sub slash {
    my $self = shift;

    if ($self->session->{account_id}) {
        my $url = $self->url_for('/dashboard');
        return($self->redirect_to($url));
    }

    $self->render();
}

sub login {
    my $self = shift;

    my $login = $self->param("login");
    my $password = $self->param("password");

    $self->stash(login => $login);
    $self->stash(password => $password);

    if ($self->param("verified")) {
        $self->stash(success => "Successfully verified: please login.");
        return($self->render());
    }

    if (!$login) {
        # $self->stash(errors => "No login given.");
        return($self->render());
    }

    if (!$password) {
        # $self->stash(errors => "No password given.");
        return($self->render());
    }

    if ($self->stash('errors')) {
        return($self->render());
    }

    my $account;
    eval {
        if ($login =~ m/@/) {
            $account = SiteCode::Account->new(email => $login, password => $password);
        }
        else {
            $account = SiteCode::Account->new(display_name => $login, password => $password);
        }
    };
    for (SiteCode::Exception->shortname(err => $@)) {
        $self->stash(errors => $@->display()) when /^NAME_TAKEN$/;
        $self->stash(errors => "Credentials not valid.") when /No email for given name and password./;
        default { $self->stash(errors => $@); }
    }

    if ($self->stash('errors') || !$account->verified()) {
        unless ($self->stash('errors')) {
            $self->stash(errors => "User does not seem to be verified");
        }
        return($self->render());
    }
    else {
        $self->session(account_display_name => $account->display_name());
        $self->session(account_id => $account->id());
        $self->session(account_email => $account->email());
        my $url = $self->url_for('/dashboard');
        return($self->redirect_to($url));
    }
}

1;
