package InfoServant::CallBlast;

use Mojo::Base 'Mojolicious::Controller';

use SiteCode::DBX;
use SiteCode::Twilio;

use Time::HiRes;

sub start_octocall {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});

    my $octo_name = $self->param("octo_name");
    my $numbers = $self->param("numbers");
    my $greeting = $self->param("greeting");

    $self->stash(octo_name => $self->param("octo_name"));
    $self->stash(internal_nbr => $internal_nbr);
    $self->stash(numbers => $self->param("numbers"));
    $self->stash(greeting => $self->param("greeting"));

    my @numbers = split(/\n/, $numbers);
    foreach my $number (@numbers) {
        $number =~ s/\D//g;
        $number =~ s/^((1)|(\+1))?/+1/;
    }

    my $octocall_id;

    my $error = "";
    my $info = "";
    my $success = "";
    my ($js, $html) = ("", "");
    if ($octo_name !~ m/\w/) {
        $error = "No OctoCall name found.";
    }
    elsif ($greeting !~ m/\w/) {
        $error = "No greeting text found.";
    }
    elsif ($numbers !~ m/\d/) {
        $error = "No numbers found.";
    }

    if ($error) {
        $html = $self->render(template => "callblast/octo_start", partial => 1);
        $js = Mojo::Util::url_escape('$("#btncall").click(onOctoCall);');
        return($self->render_json(json => { success_msg => $success, success => (!length($error)), info => $info, error => $error, html => $html, script => $js }));
    }

    my $dbx = SiteCode::DBX->new();

    eval {
        $dbx->do("INSERT INTO octocall (account_id, name, greeting, status) VALUES (?, ?, ?, 'QUEUEING')", undef, $self->session->{account_id}, $octo_name, $greeting);
        $octocall_id = $dbx->dbh->last_insert_id(undef,undef,"octocall",undef);

        foreach my $number (@numbers) {
            next unless $number =~ m/\d/ && 12 == length($number);
            $dbx->do("INSERT INTO octocall_nbr (octocall_id, number, call_status) VALUES (?, ?, 'QUEUED')", undef, $octocall_id, $number);
        }
    };
    if ($@) {
        my $e = $@;
        $html = $self->render(template => "callblast/octo_start", partial => 1);
        $js = Mojo::Util::url_escape('$("#btncall").click(onOctoCall);');
        if ($e =~ m/Duplicate/) {
            $error = "Duplicate phone number detected.";
            $dbx->do("DELETE FROM octocall_nbr WHERE octocall_id = ?", undef, $octocall_id);
            $dbx->do("DELETE FROM octocall WHERE id = ?", undef, $octocall_id);
        }
        else {
            $error = "Error while queuing OctoCall.";
            warn($e);
        }
    }
    else {
        eval {
            $dbx->do("UPDATE octocall SET status = 'NOTSTARTED' where id = ?", undef, $octocall_id);
        };
        if ($@) {
            warn($@);
            $error = "Unable to queue OctoCall.";
            $html = $self->render(template => "callblast/octo_start", partial => 1);
            $js = Mojo::Util::url_escape('$("#btncall").click(onOctoCall);');
        }
        else {
            $success = "Scheduled $octo_name to start.";
            $html = $self->render(template => "callblast/octo_success", partial => 1);
        }
    }

    return($self->render_json(json => { success_msg => $success, success => (!length($error)), info => $info, error => $error, html => $html, script => $js }));
}

sub start_infovoice {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $test_nbr = $self->param("test_nbr");
    if ($test_nbr) {
        $test_nbr =~ s/\D//g;
        $test_nbr =~ s/^((1)|(\+1))?/+1/;
    }

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});

    my $infovoice = $self->param("infovoice");

    $self->stash(voice_name => $self->param("voice_name"));
    $self->stash(numbers => $self->param("numbers"));
    $self->stash(infovoice => $infovoice);
    $self->stash(internal_nbr => $internal_nbr);
    $self->stash(test_nbr => $test_nbr);

    my $error = "";
    my $info = "";
    my $success = "";
    my ($js, $html) = ("", "");
    if ($infovoice !~ m/\w/) {
        $error = "No InfoVoice text found.";
    }
    elsif ($self->param("gonumbers") && 1 == $self->param("gonumbers")) {
        $js = Mojo::Util::url_escape('$("#btnretest").click(onInfoVoice); $("#btnsave").click(onInfoVoice);');
        $html = $self->render(template => "callblast/voice_numbers", partial => 1);
    }
    elsif ($self->param("gonumbers") && 2 == $self->param("gonumbers")) {
        my $numbers = $self->param("numbers");
        my @numbers = split(/\n/, $numbers);

        foreach my $number (@numbers) {
            $number =~ s/\D//g;
            $number =~ s/^((1)|(\+1))?/+1/;
        }

        my $voice_name = $self->param("voice_name");

        my $dbx = SiteCode::DBX->new();

        $dbx->do("INSERT INTO infovoice (account_id, name, twiml, status) VALUES (?, ?, ?, 'QUEUEING')", undef, $self->session->{account_id}, $voice_name, $infovoice);
        $infovoice_id = $dbx->dbh->last_insert_id(undef,undef,"infovoice",undef);

        eval {
            foreach my $number (@numbers) {
                next unless $number =~ m/\d/ && 12 == length($number);
                $dbx->do("INSERT INTO infovoice_nbr (infovoice_id, number) VALUES (?, ?)", undef, $infovoice_id, $number);
            }
        };
        if ($@) {
            my $e = $@;
            if ($e =~ m/Duplicate/) {
                $error = "Duplicate phone number detected.";
                $html = $self->render(template => "callblast/voice_numbers", partial => 1);
                $dbx->do("DELETE FROM infovoice_nbr WHERE infovoice_id = ?", undef, $infovoice_id);
                $dbx->do("DELETE FROM infovoice WHERE id = ?", undef, $infovoice_id);
            }
        }
        else {
            eval {
                $dbx->do("UPDATE infovoice SET status = 'NOTSTARTED' where id = ?", undef, $infovoice_id);
            };
            if ($@) {
                warn($@);
                $error = "Unable to queue InfoVoice.";
                $html = $self->render(template => "callblast/voice_numbers", partial => 1);
            }
            else {
                $success = "Scheduled $voice_name to start.";
                $html = $self->render(template => "callblast/voice_success", partial => 1);
            }
        }
    }
    elsif ($test_nbr) {
        my $words = Mojo::Util::url_escape($infovoice);
        my $twilio = SiteCode::Twilio->new();
        $twilio->speak(account_id => $self->session->{account_id}, To => $test_nbr, From => $internal_nbr, words => $words);
        $info = "Sending InfoVoice to $test_nbr.";

        $js = Mojo::Util::url_escape('$("#btnretest").click(onInfoVoice); $("#btnnumbers").click(onInfoVoice);');
        $html = $self->render(template => "callblast/voice_verify", partial => 1);
    }
    else {
        $js = Mojo::Util::url_escape('$("#btntest").click(onInfoVoice)');
        $html = $self->render(template => "callblast/voice_test", partial => 1);
    }

    return($self->render_json(json => { success_msg => $success, success => (!length($error)), info => $info, error => $error, html => $html, script => $js }));
}

1;
