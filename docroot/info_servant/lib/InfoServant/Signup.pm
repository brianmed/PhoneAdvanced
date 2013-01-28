package InfoServant::Signup;

use Mojo::Base 'Mojolicious::Controller';

use SiteCode::Account;
use SiteCode::Exception;

sub add
{
    my $self = shift;

    my $name = $self->param("name");
    my $email = $self->param("email");
    my $password = $self->param("password");
    my $vemail = $self->param("vemail");

    $self->stash(name => $self->param("name"));
    $self->stash(email => $self->param("email"));
    $self->stash(vemail => $self->param("vemail"));
    $self->stash(password => $self->param("password"));

    unless (checks(
            route => $self,
            name => $name,
            email => $email,
            vemail => $vemail,
            password => $password,
        )) {
            return($self->render());
    }

    eval {
        my $account = SiteCode::Account->addUser(
            app => $self->app,
            name => $name, 
            email => $email, 
            password => $password
        );

        $account->sendVerifyEmail();

        $self->stash(info => "Signup email sent.");
    };
    given (SiteCode::Exception->shortname(err => $@)) {
        when (undef) { $self->stash(errors => "Unknown error: " . scalar(localtime(time))); }
        when ('NAME_TAKEN') { $self->stash(errors => $@->display()); }
        when ('EMAIL_TAKEN') { $self->stash(errors => $@->display()); }
        when ('USR_WAITING_VERIFICATION') { $self->stash(errors => $@->display()); }
        when ('USR_ALREADY_VERIFIED') { $self->stash(errors => $@->display()); }
        default { 
            $self->stash(errors => $@);
        }
    }

    return($self->render());
}

sub start
{
    my $self = shift;

    my $name = $self->param("name");
    my $email = $self->param("email");
    my $password = $self->param("password");
    my $vemail = $self->param("vemail");
    my $first = $self->param("first");

    $self->stash(name => $self->param("name"));
    $self->stash(email => $self->param("email"));
    $self->stash(vemail => $self->param("vemail"));
    $self->stash(password => $self->param("password"));

    unless (checks(
            route => $self,
            name => $name,
            email => $email,
            first => $first,
            vemail => $vemail,
            password => $password,
        )) {
            return($self->render());
    }

    $self->render();
}

sub checks
{
    my %ops = @_;

    if (!$ops{name}) {
        $ops{route}->stash(errors => "Please enter a username.");
        return 0;
    }

    if ($ops{name} !~ m/^[a-zA-Z\d_]+$/) {
        $ops{route}->stash(errors => "Please enter alpha-numeric characters and the underscore only for username.");
        return 0;
    }

    if (!$ops{email}) {
        $ops{route}->stash(errors => "Please enter an email.");
        return 0;
    }

    if (!$ops{first} && !$ops{vemail}) {
        $ops{route}->stash(errors => "Please enter a verification email.");
        return 0;
    }

    if (!$ops{first} && ($ops{email} ne $ops{vemail})) {
        $ops{route}->stash(errors => "Email addresses do not match.");
        return 0;
    }

    if (!$ops{password}) {
        $ops{route}->stash(errors => "Please enter a password.");
        return 0;
    }

    if (SiteCode::Account->exists(name => $ops{name})) {
        $ops{route}->stash(errors => "Name already taken.");
        return 0;
    }

    if (SiteCode::Account->exists(email => $ops{email})) {
        $ops{route}->stash(errors => "Email already taken.");
        return 0;
    }

    if ($ops{password} !~ m/^\w{8,15}$/) {
        $ops{route}->stash(errors => "Password too short or too long.  Must be between 8 and 15 characters.");
        return 0;
    }

    return 1;
}

sub verify
{
    my $self = shift;

    my $email = $self->stash("email") || $self->param("email");
    my $verify = $self->stash("verify") || $self->param("verify");

    $self->stash(email => $self->param("email"));
    $self->stash(verify => $self->param("verify"));

    if ($email && $verify) {
        my $account;
        eval {
            $account = SiteCode::Account->new(email => $email, verify_action => 1);
        };
        given (SiteCode::Exception->shortname(err => $@)) {
            when (undef) { $self->stash(errors => "Unknown error: " . scalar(localtime(time))); }
            when ('NAME_TAKEN') { $self->stash(errors => $@->display()); }
            when ('EMAIL_TAKEN') { $self->stash(errors => $@->display()); }
            when ('USR_WAITING_VERIFICATION') { $self->stash(errors => $@->display()); }
            when ('USR_ALREADY_VERIFIED') { $self->stash(errors => $@->display()); }
            default { 
                if (my $str = SiteCode::Exception->anyerror(error_string => $@)) {
                    if ("TYPE_CONSTRAINT" eq $str) {
                        $self->stash(errors => "Unable to verify.");
                    }
                }
                else {
                    $self->stash(errors => "Unknown error: " . scalar(localtime(time)));
                }
            }
        }
        
        if ($account) {
            my $ret = $account->verify($verify);
            if ("VERIFIED" eq $ret || "ALREADY_VERIFIED" eq $ret) {
                my $url = $self->url_for('/login')->query(login => $account->display_name, verified => 1);
                $self->redirect_to($url);
            }
            else {
                $self->stash(errors => "Unable to verify.");
            }
        }
    }
    elsif ($email) {
        $self->stash(errors => "Please enter a verification code.");
    }
    elsif ($verify) {
        $self->stash(errors => "Please enter an email.");
    }

    $self->render();
}

1;

