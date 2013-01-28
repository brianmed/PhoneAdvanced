package InfoServant::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

use SiteCode::Exception;
use SiteCode::Account;
use SiteCode::DBX;
use SiteCode::Twilio;
use JSON;

sub show {
    my $self = shift;

    if (!$self->session->{account_id}) {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});
    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $stripe_code = SiteCode::DBX->new()->col("select stripe_code from account where account.id = ?", undef, $self->session->{account_id});

    $self->stash("account_sid", $account_sid);
    $self->stash("internal_nbr", $internal_nbr);
    $self->stash("external_nbr", $external_nbr);
    $self->stash("stripe_code", $stripe_code);

    $self->render();
}

sub delete_voicemail {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $recording_sid = $self->param("recording_sid");
    if (!$recording_sid) {
        return($self->render_json(json => { success => 0, error => "Unable to process voicemail."}));
    }

    my $dbx = SiteCode::DBX->new();

    my $account_sid = $dbx->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});

    my $twilio = SiteCode::Twilio->new();
    my $err = $twilio->delete_recording(account_id => $self->session->{account_id}, recording_sid => $recording_sid);

    unless ($err) {
        my $sql_recording = qq(
            select pl.inserted, 
                pl.id as phone_log_id,
                pv_rec_sid.id as pv_rec_sid_id,
                pv_rec_sid.phone_value as RecordingSid
            from phone_log pl, account, int_nbr,
                phone_key pk_rec_sid, phone_value pv_rec_sid,
                phone_key pk_sid, phone_value pv_sid
            where pl.called = int_nbr.number 
                and account_id = ? 
                and account.id = int_nbr.account_id 

                and pl.id = pk_rec_sid.phone_log_id 
                and pk_rec_sid.id = pv_rec_sid.phone_key_id 
                and pk_rec_sid.phone_key = 'RecordingSid'
                and pv_rec_sid.phone_value = ?

                and pl.id = pk_sid.phone_log_id 
                and pk_sid.id = pv_sid.phone_key_id 
                and pk_sid.phone_key = 'AccountSid'
                and pv_sid.phone_value = ?
        );

        my $recording = $dbx->row($sql_recording, undef, $self->session->{account_id}, $recording_sid, $account_sid);
        
        $dbx->do("INSERT INTO phone_key (phone_log_id, phone_key) VALUES (?, ?)", undef, $$recording{phone_log_id}, "PhoneAdvDeletedRecordingSid");
        my $phone_key_id = $dbx->dbh->last_insert_id(undef,undef,"phone_key",undef);
        $dbx->do("INSERT INTO phone_value (phone_key_id, phone_value) VALUES (?, ?)", undef, $phone_key_id, $recording_sid);
        $dbx->do("UPDATE phone_value SET phone_value = 'DELETED' where id = ?", undef, $$recording{pv_rec_sid_id});
    }

    return($self->render(json => { success_msg => "Voicemail was deleted", success => ("" eq $err ? 1 : 0), error => $err }));
}

sub voicemail {
    my $self = shift;

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});

    my $cur_page = $self->param("cur_page") || 0;
    my $skip = $cur_page * 10;
    my $sql_recordings = qq(
        select pl.inserted, 
            pv_url.phone_value as url,
            pv_rec_sid.phone_value as RecordingSid,
            pv_from.phone_value as val_from,
            pv_to.phone_value as val_to
        from phone_log pl, account, int_nbr,
            phone_key pk_url, phone_value pv_url,
            phone_key pk_rec_sid, phone_value pv_rec_sid,
            phone_key pk_from, phone_value pv_from,
            phone_key pk_to, phone_value pv_to,
            phone_key pk_sid, phone_value pv_sid
        where pl.called = int_nbr.number 
            and account_id = ? 
            and account.id = int_nbr.account_id 

            and pl.id = pk_url.phone_log_id 
            and pk_url.id = pv_url.phone_key_id 
            and pk_url.phone_key = 'RecordingUrl'

            and pl.id = pk_rec_sid.phone_log_id 
            and pk_rec_sid.id = pv_rec_sid.phone_key_id 
            and pk_rec_sid.phone_key = 'RecordingSid'
            and pv_rec_sid.phone_value != 'DELETED'

            and pl.id = pk_from.phone_log_id 
            and pk_from.id = pv_from.phone_key_id 
            and pk_from.phone_key = 'From'

            and pl.id = pk_to.phone_log_id 
            and pk_to.id = pv_to.phone_key_id 
            and pk_to.phone_key = 'To'

            and pl.id = pk_sid.phone_log_id 
            and pk_sid.id = pv_sid.phone_key_id 
            and pk_sid.phone_key = 'AccountSid'
            and pv_sid.phone_value = ?
        order by pl.inserted desc
        limit 10 offset $skip
    );

    my $recordings = SiteCode::DBX->new()->array($sql_recordings, undef, $self->session->{account_id}, $account_sid);
    
    my $tr = "";
    my $count = $skip;
    foreach my $rec (@$recordings) {
        my $url = $$rec{url};
        my $from = $$rec{val_from};
        my $to = $$rec{val_to};
        my $whence = $$rec{inserted};
        my $RecordingSid = $$rec{RecordingSid};

        next unless $to eq $internal_nbr;

        my $delete = $RecordingSid ? qq(<a href=javascript:void(0) onClick="deleteRecording('$RecordingSid')"><span class="label label-info">Delete</span></a>) : "";
        my $download = qq(<a href=$url><span class="label label-info">Download</span></a>);
        my $audio = qq(
            <audio style="vertical-align: bottom" preload="none" src="$url" type="audio/mp3" controls="controls"></audio> $download $delete</a>
        );

        ++$count;
        my $js = Mojo::Util::url_escape('$("#call_nbr").val("' . $from . '")');
        $tr .= qq(<tr><td>$count</td><td>$whence</td><td><a href="javascript:void(0)" onClick="loadHtml('call_nbr', '$js');">$from</a></td><td>$audio</td></tr>);
    }

    my ($prev, $next) = ("", "");
    if ($cur_page) {
        $prev = qq(<li><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), -1);">Previous</a></li>);
    }
    else {
        $prev = qq(<li class="disabled"><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), -1);">Previous</a></li>);
    }
    if (0 == (($count) % 10)) {
        $next = qq(<li><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), 1);">Next</a></li>);
    }
    else {
        $next = qq(<li class="disabled"><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), 1);">Next</a></li>);
    }
    my $table = "";
    if ($tr) {
        $table = qq(
            <form id=form_voicemail onsubmit="return onSubmit(this);" class="form-inline">
            <input type="hidden" id=cur_page name=cur_page value="$cur_page">
              <ul class="pager">
                  $prev
                  $next
              </ul>
            </form>

          <table class="table table-bordered table-striped table-hover">
          <caption>Last few voicemails</caption>
            <thead>
              <tr>
                <th>#</th>
                <th>Time</th>
                <th>From</th>
                <th>Audio</th>
              </tr>
            </thead>
            <tbody>
                $tr
            </tbody>
          </table>

            <form id=form_voicemail onsubmit="return onSubmit(this);" class="form-inline">
            <input type="hidden" id=cur_page name=cur_page value="$cur_page">
              <ul class="pager">
                  $prev
                  $next
              </ul>
            </form>
        );
    }
    else {
        $table = "<h3>No voicemail found.</h3>";
    }

    $self->stash(last_voicemails => $table);
}

sub recordings {
    my $self = shift;

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});

    my $cur_page = $self->param("cur_page") || 0;
    my $skip = $cur_page * 10;
    my $sql_recordings = qq(
        select pl.inserted, 
            pv_url.phone_value as url,
            pv_from.phone_value as val_from,
            pv_to.phone_value as val_to
        from phone_log pl, account, int_nbr,
            phone_key pk_url, phone_value pv_url,
            phone_key pk_from, phone_value pv_from,
            phone_key pk_to, phone_value pv_to,
            phone_key pk_sid, phone_value pv_sid
        where pl.called != int_nbr.number 
            and account_id = ? 
            and account.id = int_nbr.account_id 

            and pl.id = pk_url.phone_log_id 
            and pk_url.id = pv_url.phone_key_id 
            and pk_url.phone_key = 'RecordingUrl'

            and pl.id = pk_from.phone_log_id 
            and pk_from.id = pv_from.phone_key_id 
            and pk_from.phone_key = 'From'

            and pl.id = pk_to.phone_log_id 
            and pk_to.id = pv_to.phone_key_id 
            and pk_to.phone_key = 'To'

            and pl.id = pk_sid.phone_log_id 
            and pk_sid.id = pv_sid.phone_key_id 
            and pk_sid.phone_key = 'AccountSid'
            and pv_sid.phone_value = ?
        order by pl.inserted desc
        limit 10 offset $skip
    );

    my $recordings = SiteCode::DBX->new()->array($sql_recordings, undef, $self->session->{account_id}, $account_sid);
    
    my $tr = "";
    my $count;
    foreach my $rec (@$recordings) {
        my $url = $$rec{url};
        my $from = $$rec{val_from};
        my $to = $$rec{val_to};
        my $whence = $$rec{inserted};

        next unless $to ne $internal_nbr;

        my $audio = qq(
            <audio style="vertical-align: bottom" preload="none" src="$url" type="audio/mp3" controls="controls"></audio> <a href=$url><span class="label label-info">Download</span></a>
        );

        ++$count;
        $tr .= "<tr><td>$count</td><td>$whence</td><td>$to</to><td>$from</td><td style=\"vertical-align: middle\">$audio</td></tr>";
    }


    my ($prev, $next) = ("", "");
    if ($cur_page) {
        $prev = qq(<li><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), -1);">Previous</a></li>);
    }
    else {
        $prev = qq(<li class="disabled"><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), -1);">Previous</a></li>);
    }
    if (0 == (($count) % 10)) {
        $next = qq(<li><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), 1);">Next</a></li>);
    }
    else {
        $next = qq(<li class="disabled"><a href="javascript:void(0)" onClick="onSubmit(\$('#form_voicemail'), 1);">Next</a></li>);
    }

    my $table = "";
    if ($tr) {
        $table = qq(
            <form id=form_voicemail onsubmit="return onSubmit(this);" class="form-inline">
            <input type="hidden" id=cur_page name=cur_page value="$cur_page">
              <ul class="pager">
                  $prev
                  $next
              </ul>
            </form>

          <table class="table">
          <caption>Last few voicemails</caption>
            <thead>
              <tr>
                <th>#</th>
                <th>Time</th>
                <th>To</th>
                <th>From</th>
                <th>Audio</th>
              </tr>
            </thead>
            <tbody>
                $tr
            </tbody>
          </table>

            <form id=form_voicemail onsubmit="return onSubmit(this);" class="form-inline">
            <input type="hidden" id=cur_page name=cur_page value="$cur_page">
              <ul class="pager">
                  $prev
                  $next
              </ul>
            </form>
        );
    }
    else {
        $table = "<h3>No recordings found.</h3>";
    }

    $self->stash(last_recordings => $table);
}

sub profile {
    my $self = shift;

=for comment
    unless($self->param("find_zip") || $self->param("select_int_nbr") || $self->param("validate_external")) {
        # we have no param, so assume we need to attempt provisioning - like when it's the 1st time setting up the account
        my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});

        my $twilio = SiteCode::Twilio->new();
        $twilio->create_account(account_id => $self->session->{account_id});

        return(undef);
    }
=cut

    if ($self->param("find_zip")) {
        my $twilio = SiteCode::Twilio->new();
        my $ret = $twilio->find_numbers(account_id => $self->session->{account_id}, find_zip => $self->param("find_zip"));

        my $options = "";

        my $success = 0;
        if (ref($ret)) {
            $success = 1;

            foreach my $nbr (@{ $ret }) {
                $options .= qq(
                    <option value="$$nbr{PhoneNumber}">$$nbr{FriendlyName}</option>
                );
            }
           
        }
        elsif ("" eq $ret) {
            $success = 1;
        }

        $self->stash(found_numbers => $options);
    }
    elsif ($self->param("retrieve_nbr")) {
        my $twilio = SiteCode::Twilio->new();
        my $ret = $twilio->retrieve_numbers(account_id => $self->session->{account_id}, retrieve_nbr => 1);
        warn("ret: $ret");

        my $options = "";

        my $success = 0;
        if (ref($ret)) {
            $success = 1;

            foreach my $nbr (@{ $ret }) {
                $options .= qq(
                    <option value="$$nbr{PhoneNumber}">$$nbr{FriendlyName}</option>
                );
            }
           
        }
        elsif ("" eq $ret) {
            $success = 1;
        }

        $self->stash(retrieved_numbers => $options);
    }
    elsif ($self->param("select_int_nbr")) {
        my $twilio = SiteCode::Twilio->new();
        my $ret = $twilio->assign_number(account_id => $self->session->{account_id}, select_int_nbr => $self->param("select_int_nbr"));

        if ($ret) {
            $self->stash(errors => $ret);
        }
        else {
            $self->stash(success => "Assigned number: " . $self->param("select_int_nbr"));
        }
    }
    elsif ($self->param("validate_external")) {
        my $validate_external = $self->param("validate_external");
        $validate_external =~ s/^((1)|(\+1))?/+1/;
        my $nbr = SiteCode::DBX->new()->row("select number from ext_nbr where number = ?", undef, $validate_external);

        if ($nbr) {
            $self->stash(errors => "Number '$validate_external' already taken");
            return;
        }

        my $twilio = SiteCode::Twilio->new();
        my $ret = $twilio->validate_number(account_id => $self->session->{account_id}, validate_external => $self->param("validate_external"));

        $self->stash(validate_external => $self->param("validate_external"));

        if ($ret =~ m/validation: (.*)/) {
            my $code = $1;
            $self->stash(info => "You will need to enter code: $code");
        }
        elsif ($ret eq "Phone number is already verified.") {
            SiteCode::DBX->new()->do("INSERT INTO ext_nbr (account_id, number) VALUES (?, ?)", undef, $self->session->{account_id}, $validate_external);
            $self->stash(info => $ret);
        }
        else {
            $self->stash(errors => $ret);
        }
    }
    elsif ($self->param("process_cc")) {
        foreach my $param (qw(name number exp_month exp_year cvc)) {
            my $val = $self->param($param);
            $self->stash($param => $val);
 
            unless ($param =~ m/\w/) {
                $self->stash(errors => "Need credit card data.");
            }
        }

        unless ($self->stash('errors')) {
            my $account = SiteCode::DBX->new()->row("select account.* from account where account.id = ?", undef, $self->session->{account_id});
            my $req = &HTTP::Request::Common::POST(
                'https://api.stripe.com/v1/customers',
                Content => 
                [ 
                    description => $account->{id},
                    "card[number]" => $self->param("number"),
                    "card[exp_month]" => $self->param("exp_month"),
                    "card[exp_year]" => $self->param("exp_year"),
                    "card[cvc]" => $self->param("cvc"),
                    "card[name]" => $self->param("name"),
                    "email" => $account->{email},
                    plan => "PHONEADV",
                ] 
            );

            my $ua = LWP::UserAgent->new();
            # sk_live_Zn2IctewnvMNbnXBdu5xe1H0
            $ua->credentials("api.stripe.com:443", "Stripe", "sk_live_Zn2IctewnvMNbnXBdu5xe1H0", "");
            # $ua->credentials("api.stripe.com:443", "Stripe", "sk_test_4TaH9mX7lYqw3FMQeauk1eKc", "");
            my $res = $ua->request($req);

            my $ret = JSON::from_json($res->content());

            if ($res->is_success()) {
                my $id = $ret->{id};

                SiteCode::DBX->new()->do("UPDATE account SET stripe_code = ? WHERE id = ?", undef, $id, $account->{id});
                $self->stash(success => "Thank you for subscribing.");
                $self->stash(reload => 1);
            }
            else {
                $self->stash(errors => "Problem was detected running card.");
            }
        }
    }
    elsif ($self->param("profile_group")) {
        my $dbx = SiteCode::DBX->new();
        my $account = $dbx->row("select account.* from account where account.id = ?", undef, $self->session->{account_id});

        my $email_rcpt_voicemail = $self->param("email_rcpt_voicemail");
        my $attach_message = $self->param("attach_message");

        my $col = $dbx->col("SELECT id from profile where account_id = ?", undef, $$account{id});
        if ($col) {
            $dbx->do("UPDATE profile SET email_rcpt_voicemail = ?, attach_message = ? WHERE account_id = ?", undef, ($email_rcpt_voicemail ? "YES" : undef), ($attach_message ? "YES" : undef), $$account{id});
        }
        else {
            $dbx->do("INSERT INTO profile (account_id, email_rcpt_voicemail, attach_message) values (?, ?, ?)", undef, $$account{id}, ($email_rcpt_voicemail ? "YES" : undef), ($attach_message ? "YES" : undef));
        }
    }
    elsif ($self->param("cancel_account")) {
        my $account = SiteCode::DBX->new()->row("select account.* from account where account.id = ?", undef, $self->session->{account_id});

        my $req = &HTTP::Request::Common::DELETE(
            "https://api.stripe.com/v1/customers/$$account{stripe_code}/subscription",
        );
        my $ua = LWP::UserAgent->new();
        $ua->credentials("api.stripe.com:443", "Stripe", "sk_live_Zn2IctewnvMNbnXBdu5xe1H0", "");
        # $ua->credentials("api.stripe.com:443", "Stripe", "sk_test_4TaH9mX7lYqw3FMQeauk1eKc", "");
        my $res = $ua->request($req);
        if ($res->is_success()) {
            SiteCode::DBX->new()->do("UPDATE account SET stripe_code = NULL WHERE id = ?", undef, $$account{id});
            $self->stash(success => "Thank you for your service.");
            $self->stash(reload => 1);
        }
        else {
            $self->stash(success => "Error cancelling: please call support.");
        }
    }
}

sub octocall {
    my $self = shift;

    my $sql_octocalls = qq(
        select 
            octocall.*, octocall_nbr.number, octocall_nbr.num_calls, octocall_nbr.last_call, octocall_nbr.call_status
        from octocall, octocall_nbr
        where octocall.account_id = ?
            and octocall_id = octocall.id
        order by octocall.inserted desc, call_status
    );

    my $calls = SiteCode::DBX->new()->array($sql_octocalls, undef, $self->session->{account_id});
    
    my %tr = ();
    foreach my $call (@$calls) {
        ++$tr{$$call{id}}{count};
        $tr{$$call{id}}{name} = $$call{name};
        $tr{$$call{id}}{status} = $$call{status};
        $tr{$$call{id}}{tr} .= "<tr><td>$tr{$$call{id}}{count}</td><td>$$call{number}</to><td>$$call{last_call}</td><td>$$call{call_status}</td></tr>";
    }

    my $table = "";
    if (%tr) {
        foreach my $k (reverse sort({ $a <=> $b } keys %tr)) {
            my $name = $tr{$k}{name};
            my $status = $tr{$k}{status};
            my $tr = $tr{$k}{tr};
            $table .= qq(
              <table class="table">
              <caption>OctoCall Log for $name ($status)</caption>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Number</th>
                    <th>Last Call</th>
                    <th>Call Status</th>
                  </tr>
                </thead>
                <tbody>
                    $tr
                </tbody>
              </table>
            );
        }
    }
    else {
        $table = "<h3>No OctoCall logs found.</h3>";
    }

    $self->stash(last_octocalls => $table);
}

sub infovoice {
    my $self = shift;

    my $sql_stop_the_voices = qq(
        select 
            infovoice.*, infovoice_nbr.number, infovoice_nbr.num_calls, infovoice_nbr.last_call, infovoice_nbr.status as call_status
        from infovoice, infovoice_nbr
        where infovoice.account_id = ?
            and infovoice_id = infovoice.id
        order by infovoice.inserted desc, call_status
    );

    my $calls = SiteCode::DBX->new()->array($sql_stop_the_voices, undef, $self->session->{account_id});
    
    my %tr = ();
    foreach my $call (@$calls) {
        ++$tr{$$call{id}}{count};
        $tr{$$call{id}}{name} = $$call{name};
        $tr{$$call{id}}{status} = $$call{status};
        $tr{$$call{id}}{tr} .= "<tr><td>$tr{$$call{id}}{count}</td><td>$$call{number}</to><td>$$call{last_call}</td><td>$$call{call_status}</td></tr>";
    }

    my $table = "";
    if (%tr) {
        foreach my $k (reverse sort({ $a <=> $b } keys %tr)) {
            my $name = $tr{$k}{name};
            my $status = $tr{$k}{status};
            my $tr = $tr{$k}{tr};
            $table .= qq(
              <table class="table">
              <caption>InfoVoice Log for $name ($status)</caption>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Number</th>
                    <th>Last Call</th>
                    <th>Call Status</th>
                  </tr>
                </thead>
                <tbody>
                    $tr
                </tbody>
              </table>
            );
        }
    }
    else {
        $table = "<h3>No InfoVoices found.</h3>";
    }

    $self->stash(last_infovoices => $table);
}

sub retrieve_html {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render(text => "Session has expired.  <a href=http://phoneadvanced.com/login>Login</a>."));
    }

    my $page = $self->param("page");

    if ("voicemail" eq $page) {
        $self->voicemail();
    }
    if ("recordings" eq $page) {
        $self->recordings();
    }
    if ("profile" eq $page) {
        $self->profile();
    }
    if ("start_infovoice" eq $page) {
        $self->infovoice();
    }
    if ("start_octocall" eq $page) {
        $self->octocall();
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});
    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $stripe_code = SiteCode::DBX->new()->col("select stripe_code from account where account.id = ?", undef, $self->session->{account_id});
    $self->stash(account_sid => $account_sid);
    $self->stash(internal_nbr => $internal_nbr);
    $self->stash(external_nbr => $external_nbr);
    $self->stash(stripe_code => $stripe_code);

    my $profile = SiteCode::DBX->new()->row("select profile.* from profile where profile.account_id = ?", undef, $self->session->{account_id});
    my $checked = {};
    if ($$profile{email_rcpt_voicemail}) {
        $checked->{email_rcpt_voicemail} = " checked";
    }
    if ($$profile{attach_message}) {
        $checked->{attach_message} = " checked";
    }
    $self->stash(checked => $checked);

    # my $html = $self->render(template => "dashboard/$page", partial => 1);
    return($self->render(template => "dashboard/$page", format => "html"));
    # return($self->render_json(json => { success => 1, error => "", html => $html}));
}

sub retrieve_js {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $page = $self->param("page");

    # my $html = $self->render(template => "dashboard/$page", partial => 1);
    return($self->render(template => "dashboard/$page", format => "js"));
    # return($self->render_json(json => { success => 1, error => "", html => $html}));
}

sub provision {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $twilio = SiteCode::Twilio->new();
    my $ret = $twilio->create_account(account_id => $self->session->{account_id});

    return($self->render(json => { success => ("" eq $ret ? 1 : 0), error => $ret }));
}

sub call_nbr {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});
    # my $auth_token = SiteCode::DBX->new()->col("select AuthToken from account, subaccount where user.id = subaccount.user_id AND  user.id = ", undef, $self->session->{user_id});
    # warn("account_sid: $account_sid");

    my $to = $self->param("call_nbr");
    $self->stash(call_nbr => $to);

    unless ($to) {
        return($self->render_json({ success => 0, error => "No number given." }));
    }

    my $twilio = SiteCode::Twilio->new();

    my $ret = $twilio->initiate_web_merge(
        account_sid => $account_sid, 
        internal_nbr => $internal_nbr, 
        external_nbr => $external_nbr, 
        to => $to,
        record => $self->param("record_call") || 0,
    );
    if (ref($ret)) {
        $ret = "";
    }

    return($self->render(json => { success => ("" eq $ret ? 1 : 0), error => $ret, to => $to }));
}

sub quick_conference {
    my $self = shift;

    if (!$self->session->{account_id}) {
        return($self->render_json(json => { success => 0, error => "Session has expired."}));
    }

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $self->session->{account_id});
    # my $auth_token = SiteCode::DBX->new()->col("select AuthToken from user, subaccount where user.id = subaccount.user_id AND  user.id = ", undef, $self->session->{user_id});
    # warn("account_sid: $account_sid");

    my $numbers = $self->param("numbers") || "";
    $self->stash(numbers => $self->param("numbers"));

    my $twilio = SiteCode::Twilio->new();

    my $err = "";
    my @numbers = split(/\n/, $numbers);
        warn("numbers: $numbers");
    foreach my $number (@numbers) {
        $number =~ s/\D//g;
        $number =~ s/^((1)|(\+1))?/+1/;
        warn("number: $number");

        my $ret = $twilio->quick_conference(
            account_id => $self->session->{account_id},
            account_sid => $account_sid, 
            From => $internal_nbr, 
            To => $number,
        );
        unless (ref($ret)) {
            $err = $ret;
            last;
        }
    }

    return($self->render(json => { success => ("" eq $err ? 1 : 0), error => $err }));
}

sub logout {
    my $self = shift;

    my @keys = keys %{ $self->session };

    foreach my $k (@keys) {
        delete($self->session->{$k});
    }

    my $url = $self->url_for('/');
    return($self->redirect_to($url));
}

1;
