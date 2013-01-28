package SiteCode::Exception;

use strict;
use warnings;

use Scalar::Util;

my %Exceptions = (
    "SiteCode::Account" => {
        "NAME_TAKEN" => {
            FOR_USER => "Username already taken.",
            FIND_RE => qr/constraint.*u101_3/ms,
        },
        "EMAIL_TAKEN" => {
            FOR_USER => "Email already taken.",
            FIND_RE => qr/constraint.*u101_2/ms,
        },
        "TYPE_CONSTRAINT" => {
            FIND_RE => qr/does not pass the type constraint/ms,
        },
        "USR_ALREADY_VERIFIED" => {
            FOR_USER => "Email already taken.",
        },
        "USR_WAITING_VERIFICATION" => {
            FOR_USER => "Waiting on verifcation.",
        },
    },
);

sub package
{
    my $self = shift;

    return($self->{_package});
}

sub anyerror
{
    my $self = shift;
    my %ops = @_;

    foreach my $package (keys %Exceptions) {
        my $exceptions = $Exceptions{$package};

        foreach my $name (keys %{ $exceptions }) {
            my $exception = $exceptions->{$name};
            if ($exception->{FIND_RE}) {
                if ($ops{error_string} =~ m/$$exception{FIND_RE}/) {
                    return($$exception{FOR_USER} || $name);
                }
            }
        }
    }

    return(undef);
}

sub shortname
{
    my $self = shift;
    my %ops = @_;

    my $err;

    if (ref($self)) {
        $err = $self;
    }
    else {
        $err = $ops{err};
    }

    my $err_blessed = Scalar::Util::blessed($err);
    if ($err_blessed && "SiteCode::Exception" ne $err_blessed) {  # could be Mojox::Exception
        return($err);
    }
    elsif (!$err_blessed) {
        return($err);
    }

    $err->{app}->log->debug("package: " . $err->package());
    my $exceptions = $Exceptions{$err->package()};

    if ($err->{error_name}) {
        if ($err_blessed) {
            $err->{app}->log->debug("error_name: " . $err->{error_name});
        }
        return($err->{error_name});
    }

    foreach my $name (keys %{ $exceptions }) {
        my $exception = $exceptions->{$name};
        if ($exception->{FIND_RE}) {
            if ($err->{error_string} =~ m/$$exception{FIND_RE}/) {
                return($name);
            }
        }
    }

    return(undef);
}

sub display
{
    my $self = shift;

    my $exceptions = $Exceptions{$self->package()};

    if ($self->{error_name}) {
        return($exceptions->{$self->{error_name}}{FOR_USER});
    }

    foreach my $name (keys %{ $exceptions }) {
        my $exception = $exceptions->{$name};
        if ($exception->{FIND_RE}) {
            if ($self->{error_string} =~ m/$$exception{FIND_RE}/) {
                return($exception->{FOR_USER});
            }
        }
    }
}

sub new
{
    my $self = shift;

    my %ops = @_;

    my $blessed = Scalar::Util::blessed($ops{error_string});
    if ($blessed && "SiteCode::Exception" eq $blessed) {
        return($ops{error_string});
    }

    my $err = { app => $ops{app}, _package => $ops{package} };

    if ($ops{error_name}) {
        my $error_string = $Exceptions{$$err{_package}}{$ops{error_name}}{FOR_USER};

        $err->{error_string} = $error_string;
        $err->{error_name} = $ops{error_name};
    }
    else {
        $err->{error_string} = $ops{error_string};
    }

    $err->{app}->log->debug("error_name: " . $err->{error_name});
    $err->{app}->log->debug("error_string: " . $err->{error_string});

    bless($err, $self);
}

1;
