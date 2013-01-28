package SiteCode::Account;

use Moose;
use namespace::autoclean;
use SiteCode::DBX;
use Email::Valid;
use Moose::Util::TypeConstraints;
use Digest::MD5;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;

use SiteCode::Site;

subtype 'Email'
    => as 'Str'
    => where { Email::Valid->address($_) }
    => message { $_ ? "$_ is not a valid email address" : "No value given for address validation" };

has 'dbx' => ( isa => 'SiteCode::DBX', is => 'ro', default => sub { SiteCode::DBX->new() } );
has 'id' => ( isa => 'Int', is => 'rw' );
has 'email' => ( isa => 'Email', is => 'rw' );
has 'name' => ( isa => 'Str', is => 'rw' );
has 'password' => ( isa => 'Str', is => 'rw' );
has 'display_name' => ( isa => 'Str', is => 'rw' );
has 'verify_action' => ( isa => 'Str', is => 'rw' );

sub _lookup_id {
    my $self = shift;

    return($self->dbx()->col("SELECT id FROM account WHERE email = ?", undef, $self->email()));
}

sub _lookup_email {
    my $self = shift;

    return($self->dbx()->col("SELECT email FROM account WHERE id = ?", undef, $self->id()));
}

sub _lookup_password {
    my $self = shift;

    return($self->dbx()->col("SELECT password FROM account WHERE id = ?", undef, $self->id()));
}

sub _given_display_name {
    my $self = shift;

    my $email = $self->dbx()->col("SELECT email FROM account WHERE name = ? AND display_name = ?", undef, $self->name(), $self->display_name());
    unless ($email) {
        die("No email for given name and password.\n");
    }
    return($email);
}

sub _verify_id_and_email {
    my $self = shift;

    return($self->dbx()->success("SELECT 1 FROM account WHERE id = ? AND email = ?", undef, $self->id(), $self->email()));
}

sub _verify_display_name_and_email {
    my $self = shift;

    return($self->dbx()->success("SELECT 1 FROM account WHERE display_name = ? AND name = ? AND email = ?", undef, $self->display_name(), $self->name(), $self->email()));
}

sub BUILD {
    my $self = shift;

    if (!$self->id()) {
        unless ($self->verify_action()) {
            if (!$self->password()) {
                die("Please pass in a password.\n");
            }
        }
    }

    if ($self->id() && $self->email()) { # verify user passed in columns
        unless ($self->_verify_id_and_email()) {
            die("The columns id and email do not match.\n");
        }
    }
    elsif ($self->id()) {
        $self->email($self->_lookup_email());
        $self->password($self->_lookup_password());
    }
    elsif ($self->email()) {
        $self->id($self->_lookup_id());
        if ($self->verify_action()) {
            $self->password($self->_lookup_password());
        }
    }
    elsif ($self->display_name()) {
        $self->name(uc $self->display_name());
        $self->email($self->_given_display_name());
        $self->id($self->_lookup_id());
    }

    if (!$self->id() && !$self->email()) {
        die("No id or email given.\n");
    }

    unless ($self->id() && $self->email()) {
        die("Need both id and email.\n");
    }

    unless ($self->_verify_id_and_email()) {  # verify our looked up columns
        die("The columns id and email do not match.\n");
    }

    unless ($self->_verify_display_name_and_email()) {  # verify our looked up columns
        die("The columns name and email do not match.\n");
    }

    unless($self->chkPw($self->password())) {
        die("Credentials mis-match.\n");
    }

    $self->display_name($self->dbx()->col("SELECT display_name FROM account WHERE id = ?", undef, $self->id()));
}

sub addUser
{
    my $self = shift;
    my %ops = @_;

    my $name = $ops{name};
    my $email = $ops{email};
    my $password = $ops{password};

    my $time = time();
    my $md5 = Digest::MD5::md5_hex($time);

    eval {
        my $dbx = SiteCode::DBX->new();

        my $exists = $dbx->success("SELECT 1 FROM account WHERE name = ? AND email = ? AND password = ?", undef, $name, lc $email, $password);
        if ($exists) {
            my $verified = $dbx->col("SELECT verified FROM account WHERE name = ? AND email = ? AND password = ?", undef, $name, lc $email, $password);
            if ($verified) {
                if ("SUCCESS" eq $verified) {
                    die SiteCode::Exception->new(app => $ops{app}, error_name => "USR_ALREADY_VERIFIED", package => __PACKAGE__);
                }
                else {
                    die SiteCode::Exception->new(app => $ops{app}, error_name => "USR_WAITING_VERIFICATION", package => __PACKAGE__);
                }
            }
        }

        $dbx->do("INSERT INTO account (name, display_name, email, password, verified, stripe_code) VALUES (?, ?, ?, ?, ?, NOW())", undef, uc $name, $name, lc $email, $password, $md5);
    };
    if ($@) {
        die SiteCode::Exception->new(app => $ops{app}, error_string => $@, package => __PACKAGE__);
    }

    my $dbx = SiteCode::DBX->new();
    my $id = $dbx->col("SELECT id FROM account WHERE name = ? AND email = ?", undef, uc $name, lc $email);
    my $account = SiteCode::Account->new(id => $id);

    return($account);
}

sub sendVerifyEmail
{
    my $self = shift;
    my %ops = @_;

    my $email = $self->email;
    my $md5 = SiteCode::DBX->new()->col("SELECT verified FROM account WHERE id = ?", undef, $self->id());

    my $mail = Email::Simple->create(
        header => [
            To      => $email,
            From    => 'signup@phoneadvanced.com',
            Subject => "Welcome to Phone Advanced",
        ],
        body => "Thank you for signing up with Phone Advanced.\nPlease follow the link below to verify your email address:\n\nEmail: $email\nToken: $md5\n\nhttp://phoneadvanced.com/verify/$email/$md5\n",
    );

    my $dir = POSIX::strftime("/opt/infoservant.com/emails/%F", localtime(time));
    mkdir $dir unless -d $dir;
    my ($fh, $filename) = File::Temp::tempfile("verifyXXXXX", DIR => $dir, SUFFIX => '.txt', UNLINK => 0);
    print($fh $mail->as_string);
    warn("filename: $filename");

    my $site_config = SiteCode::Site->config();
    my $transport = Email::Sender::Transport::SMTP::TLS->new({
            host => $site_config->{smtp_host},
            port => $site_config->{smtp_port},
            username => $site_config->{smtp_user},
            password => $site_config->{smtp_pass},
    });
    sendmail($mail, {transport => $transport });
}

sub sendVoicemailEmail
{
    my $self = shift;
    my %ops = @_;

    my $email = $self->email;

    my $mail = Email::Simple->create(
        header => [
            To      => $email,
            From    => 'noreply@phoneadvanced.com',
            Subject => "Voicemail from $ops{From}",
        ],
        body => "Thank you for using Phone Advanced.\nYou have received a voicemail from $ops{From} ($ops{FromCity}, $ops{FromState}  $ops{FromZip}).\n\nAudio: $ops{RecordingUrl}\n",
    );

    my $dir = POSIX::strftime("/opt/infoservant.com/emails/%F", localtime(time));
    mkdir $dir unless -d $dir;
    my ($fh, $filename) = File::Temp::tempfile("verifyXXXXX", DIR => $dir, SUFFIX => '.txt', UNLINK => 0);
    print($fh $mail->as_string);
    warn("filename: $filename");

    my $site_config = SiteCode::Site->config();
    my $transport = Email::Sender::Transport::SMTP::TLS->new({
            host => $site_config->{smtp_host},
            port => $site_config->{smtp_port},
            username => $site_config->{smtp_user},
            password => $site_config->{smtp_pass},
    });
    sendmail($mail, {transport => $transport });
}

sub chkPw
{
    my $self = shift;
    my $pw = shift;

    my $ret = $self->dbx()->col("SELECT password FROM account WHERE id = ?", undef, $self->id());

    return($pw eq $ret);
}

sub exists {
    my $class = shift;

    my %opt = @_;

    if ($opt{email}) {
        return(SiteCode::DBX->new()->col("SELECT id FROM account WHERE email = ?", undef, lc $opt{email}));
    }
    elsif ($opt{name}) {
        return(SiteCode::DBX->new()->col("SELECT id FROM account WHERE name = ?", undef, uc $opt{name}));
    }
}

sub verify {
    my $self = shift;
    my $v = shift;

    my $dbx = SiteCode::DBX->new();

    my $verify = $dbx->col("SELECT verified FROM account WHERE id = ?", undef, $self->id());
    if ("SUCCESS" eq $verify) {
        return("ALREADY_VERIFIED");
    }

    warn("v: $v: verify: $verify");
    if ($v eq $verify) {
        $dbx->do("UPDATE account SET verified = 'SUCCESS' WHERE id = ?", undef, $self->id());
        return("VERIFIED");
    }

    return('');
}

sub verified {
    my $self = shift;

    my $dbx = SiteCode::DBX->new();

    my $ret = $dbx->col("SELECT 1 FROM account WHERE id = ? AND verified = 'SUCCESS'", undef, $self->id());

    return($ret);
}

__PACKAGE__->meta->make_immutable;

1;


