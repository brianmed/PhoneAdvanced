package InfoServant::Phone;

# 
# Left:
# A Simple Conference Room For Conference Calls
# Hosted IVR.
# Custom surveys.
# Allow for hosted data.
# Schedule annoucements.
# Subscription or al-a-carte.
# Google contact integration for lookups.
# Tweak site layout.
# CRM Integrations.
#   Salesforce
#   SugarCRM
#   ?Zoho?
# Cancel dialog box: are you sure.
# InfoVoice: Upload speech and record via microphone.
# Email when any voicemail gets recorded.
# Email when specific voicemail gets recorded.
# Record OctoCall
# Voicemails via email.
# Voicemails via sms.
# Resend verify link.
# Provide instructions for multiple carriers.
# Press one to get a callback for InfoVoice.
# Georoute calls by area code, zip code, or geocode
#   Does your company have multiple locations or franchises? Route calls based on area code,
#   zip code or geocode (using a reverse lookup) to the nearest location
# Autoschedule
#
# Done:
# Paginate.
# Verify Phone layout.
# Session has expired: *login*.
# Download voicemail
# Deauthorize.
# Retrieve a twilio number (rather than buy).
# Bill the user / pay us.
#
# Skype: +1 479 431 6365 
#
# Intelligent call forwarding.
#   Time of day
#   Who is calliing
# SMS when any voicemail gets recorded.
# SMS when specific voicemail gets recorded.
# Programmable ivr (menu tree)
# Groups
# Phone Surveys <- list of numbers that are "press 1 for Obamacare, 2 for no"
#   Polls
#   Info / Alert
#   Follow up call
#
# Input PIN to be connected.
# Input PIN for voicemail.
#
# Web based voicemail
#   
# Dial from web
#
# Record phone calls
#
# A Business Phone Number That Forwards To Your Cell Phone
#
# Voicemail that is protected by pin
#
# Calendar appointments spoken
#
# Call me when get email from X or Y
#
# # (207) 775-4321 <-- time and temp
#
#   <!-- Ensure the "Voice Request URL" for your TelAPI number points to wherever this XML
#   document is hosted -->
#    
#    <!-- An TwiML document is made up of various XML elements nested in the response
#    element -->
#    <Response>
#    <!-- The <Dial> element starts an outgoing call. Replace this number with the number
#    of the phone you would like to receive the call -->
#        <Dial>15555555555</Dial>
#        </Response>
#
# A Simple Conference Room For Conference Calls
#
#   <Response>
#       <Dial>
#               <Conference startConferenceOnEnter="true" maxParticipants="10">
#                           Conference Call Example Room
#                                   </Conference>
#                                       </Dial>
#                                       </Response>
#
# 
# Record incoming and outgoing calls
#
# A Professional Sounding IVR Menu With Departments
#
# Screening Incoming Calls
#
# Block unlimited callers
# 
# Mass call and then connect to live operator.
#
# CRM: click to call and create contact on missed call
#
# Home automation
#
# Custom callbacks
#
#  Blow Up My Phone allows users to schedule incoming calls and text messages to their
#  phones as a way to escape from those awkward moments we all know too well. 
#
#  For incoming calls, Jonas is using custom caller IDs which allow his users to make
#  incoming calls come from any number they'd like. "Oh look, my mother's calling. I gotta
#  run!" As Jonas puts it, "It allows a simple phone call or text message to be used as a
#  social tool providing the user credible ‘social currency’ in real time."
#

use Mojo::Base 'Mojolicious::Controller';

use SiteCode::DBX;
use SiteCode::Account;
use SiteCode::Twilio;

use Time::HiRes;

sub save_params {
    my $self = shift;

    my $sub = (caller(1))[3];

    my @params = $self->param();

    my $dir = "";

    foreach (qw(1 2 3 4 5)) {
        my ($sec, $micro) = Time::HiRes::gettimeofday();
        $micro = sprintf("%06d", $micro);
        my $time = join(".", ($sec, $micro));

        if (mkdir("/opt/infoservant.com/phone/$time.$sub")) {
            $dir = "/opt/infoservant.com/phone/$time.$sub";
            last;
        }
    }

    my $caller = $self->param("Caller") || 'nf';
    my $called = $self->param("Called") || 'nf';

    my $dbx = SiteCode::DBX->new();

    $dbx->do("INSERT INTO phone_log (sub, caller, called) VALUES (?, ?, ?)", undef, $sub, $caller, $called);
    my $phone_log_id = $dbx->dbh->last_insert_id(undef,undef,"phone_log",undef);

    foreach my $key (@params) {
        next if $key =~ /^adv_/;
        my $value = $self->param($key);

        eval {
            if (-d $dir) {
                open(my $fh, ">", "$dir/$key") or next;
                print($fh $value);
                close($fh);
            }
        };

        $dbx->do("INSERT INTO phone_key (phone_log_id, phone_key) VALUES (?, ?)", undef, $phone_log_id, $key);
        my $phone_key_id = $dbx->dbh->last_insert_id(undef,undef,"phone_key",undef);
        $dbx->do("INSERT INTO phone_value (phone_key_id, phone_value) VALUES (?, ?)", undef, $phone_key_id, $value);
    }
}

sub save_xml {
    my $self = shift;
    my $xml = shift;

    my $sub = (caller(1))[3];

    my @params = $self->param();

    my $dir = "";

    foreach (qw(1 2 3 4 5)) {
        my ($sec, $micro) = Time::HiRes::gettimeofday();
        $micro = sprintf("%06d", $micro);
        my $time = join(".", ($sec, $micro));

        if (mkdir("/opt/infoservant.com/xml/$time.$sub")) {
            $dir = "/opt/infoservant.com/xml/$time.$sub";
            last;
        }
    }

    eval {
        if (-d $dir) {
            open(my $fh, ">", "$dir/TwiML") or die;
            print($fh $xml);
            close($fh);
        }
    };
}

sub deauthorize {
    my $self = shift;

    save_params($self);

    if ($self->param("AccountSid")) {
        my $twilio = SiteCode::Twilio->new();
        my $ret = $twilio->deauthorize_account(account_sid => $self->param("AccountSid"));
    }

    $self->render(text => "");
}

sub authorized {
    my $self = shift;

    save_params($self);

    if ($self->param("AccountSid")) {
        my $twilio = SiteCode::Twilio->new();
        my $ret = $twilio->authorize_account(account_id => $self->session->{account_id}, account_sid => $self->param("AccountSid"));
    }

    my $url = $self->url_for('/dashboard');
    return($self->redirect_to($url));
}

sub initiate_web_merge {
    my $self = shift;

    save_params($self);

    my $from = $self->param("adv_from");
    my $to = $self->param("adv_to");

    my $TwiML = qq(
        <Response>
            <Say>Connecting.</Say>
            <Dial> $to </Dial>
        </Response>
    );

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub initiate_conference {
    my $self = shift;

    save_params($self);

    my $TwiML = qq(
        <Response>
        <Dial>
            <Conference callbackUrl="http://infoservant.com/ivr/voice/dial/conference" startConferenceOnEnter="true" endConferenceOnExit="true" beep="true" hangupOnStar="true" maxParticipants="5">
                4795217904
            </Conference>
        </Dial>
        </Response>
    );

    # <Dial callerId="4795217904" action="http://infoservant.com/ivr/voice/dial/action" method="POST">4796298988</Dial>

    $self->render(text => $TwiML);
}

sub receive_call {
    my $self = shift;

    save_params($self);

    my $forwarded_from = $self->param("ForwardedFrom");
    my $account_sid = $self->param("AccountSid");
    my $caller = $self->param("Caller");
    # my $subaccount = SiteCode::DBX->new()->row("select subaccount.* from subaccount where Sid = ?", undef, $account_sid);
    my $account = SiteCode::DBX->new()->row("select account.* from account where AccountSid = ?", undef, $account_sid);
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $$account{id});
    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as internal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $$account{id});

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Say>Connecting.</Say>
            <Dial callerId="$caller" action="http://infoservant.com/ivr/voice/cb_dial" method="POST"> <Client>4794399010</Client> </Dial>
        </Response>
    );
    #  <Dial callerId="$caller" action="http://infoservant.com/ivr/voice/cb_dial" method="POST"> $external_nbr </Dial>

    my $Called = $self->param("Called");
    my $Caller = $self->param("Caller");
    my $From = $self->param("From");
    my $To = $self->param("To");

    if ($Called eq $Caller && $Caller eq $From && $From eq $To && $Called eq $internal_nbr && $forwarded_from eq $external_nbr) { # i think this is a web merge that was not picked up by *our* user
        my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
            <Response>
                <Reject reason="busy" />
            </Response>
        );

        save_xml($self, $TwiML);

        $self->res->headers->content_type('text/xml');
        return($self->render(text => $TwiML));
    }

    if ($forwarded_from && $external_nbr && $forwarded_from eq $external_nbr) { # voicemail
        my $code = "";
        foreach my $digit (qw(1 2 3 4)) {
            $code .= int(rand(10));
        }

        my $digits = $external_nbr;
        $digits =~ s/\+1//;
        $digits =~ s/\d/$&, /g;
        $digits =~ s#, $##;

        $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
            <Response>
                <Say>You have reached the voicemail of $digits.</Say>
                <Record maxLength="120" timeout="2" action="http://infoservant.com/ivr/voice/cb_record" method="POST" />
            </Response>
        );
    }

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub straight_voicemail {
    my $self = shift;

    save_params($self);

    my $from = $self->param("adv_from");
    my $to = $self->param("adv_to");
    my $record = $self->param("adv_record");
    my $CallSid = $self->param("CallSid");
    my $words = $self->param("words");
    $words = Mojo::Util::url_unescape($words) || "Connecting.";

    my $record_string = "";
    if ($record) {
        $record_string = ' record="true" ';
    }
    my $callsid = "";
    if ($CallSid) {
        $callsid = "/$CallSid";
    }
    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Say>$words</Say>
            <Dial Timeout="1" callerId="$from"> $to </Dial>
            <Dial $record_string callerId="$from" action="http://infoservant.com/ivr/voice/cb_dial$callsid" method="POST"> $to </Dial>
        </Response>
    );

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub web_merge {
    my $self = shift;

    save_params($self);

    my $from = $self->param("adv_from");
    my $to = $self->param("adv_to");
    my $record = $self->param("adv_record");
    my $CallSid = $self->param("CallSid");
    my $words = $self->param("words");
    $words = Mojo::Util::url_unescape($words) || "Connecting.";

    my $record_string = "";
    if ($record) {
        $record_string = ' record="true" ';
    }
    my $callsid = "";
    if ($CallSid) {
        $callsid = "/$CallSid";
    }
    my $TwiML = qq(
        <Response>
            <Say>$words</Say>
            <Dial $record_string callerId="$from" action="http://infoservant.com/ivr/voice/cb_dial$callsid" method="POST"> $to </Dial>
        </Response>
    );

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub conference {
    my $self = shift;

    save_params($self);

    $self->render(data => "");
}

sub quick_conference {
    my $self = shift;

    save_params($self);

    my $from = $self->param("quick_from");

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Dial>
                <Conference>$from</Conference>
            </Dial>
        </Response>
    );

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub hangup {
    my $self = shift;

    save_params($self);

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Hangup/>
        </Response>
    );

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub cb_verify {
    my $self = shift;

    save_params($self);

    my $external_nbr = $self->param("To");
    my $status = $self->param("VerificationStatus");
    my $account_sid = $self->param("AccountSid");

    if ("success" eq $status) {
        my $account = SiteCode::DBX->new()->row("select account.* from account where AccountSid = ?", undef, $account_sid);
        SiteCode::DBX->new()->do("INSERT INTO ext_nbr (account_id, number) VALUES (?, ?)", undef, $$account{id}, $external_nbr);
    }

    $self->render(text => "");
}

sub cb_gather {
    my $self = shift;

    save_params($self);

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Hangup/>
        </Response>
    );

    my $forwarded_from = $self->param("ForwardedFrom");
    my $account_sid = $self->param("AccountSid");
    my $caller = $self->param("Caller");
    my $subaccount = SiteCode::DBX->new()->row("select subaccount.* from subaccount where Sid = ?", undef, $account_sid);
    my $account = SiteCode::DBX->new()->row("select account.* from account where id = ?", undef, $$subaccount{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $$account{id});

    warn("account: $account");

    if ($forwarded_from && $external_nbr && $forwarded_from eq $external_nbr) { # voicemail
        if ("781" eq $self->param("Digits")) {
            $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
                <Response>
                    <Record maxLength="120" timeout="2" action="http://infoservant.com/ivr/voice/cb_record" method="POST" />
                </Response>
            );
        }
    }
    else {
        if ("488" eq $self->param("Digits")) {
            $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
                <Response>
                    <Say>Connecting.</Say>
                    <Dial callerId="$caller" action="http://infoservant.com/ivr/voice/cb_dial" method="POST"> $external_nbr </Dial>
                </Response>
            );
        }
    }

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub cb_dial {
    my $self = shift;

    save_params($self);

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Hangup/>
        </Response>
    );

    save_xml($self, $TwiML);

    my $CallSid = $self->param("CallSid");

    if ($CallSid) {
        SiteCode::DBX->new()->do("UPDATE octocall_nbr set call_status = 'DONE' where CallSid = ?", undef, $CallSid);
    }

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub cb_record {
    my $self = shift;

    save_params($self);

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Hangup/>
        </Response>
    );

    my $RecordingUrl = $self->param("RecordingUrl");
    my $ForwardedFrom = $self->param("ForwardedFrom");
    if ($RecordingUrl) {
        my $ext_nbr = SiteCode::DBX->new()->row("select ext_nbr.* from ext_nbr where ext_nbr.number = ?", undef, $ForwardedFrom);
        my $account = SiteCode::DBX->new()->row("select account.* from account where account.id = ?", undef, $$ext_nbr{account_id});
        my $profile = SiteCode::DBX->new()->row("select profile.* from profile where profile.account_id = ?", undef, $$account{id});

        if ($$profile{email_rcpt_voicemail}) {
            my $account = SiteCode::Account->new(id => $$account{id});
            $account->sendVoicemailEmail(
                From => $self->param("From"),
                FromCity => $self->param("FromCity"),
                FromState => $self->param("FromState"),
                FromZip => $self->param("FromZip"),
                RecordingUrl => $self->param("RecordingUrl"),
            );
        }
    }

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

sub dial_ron_medley {
    my $self = shift;

    save_params($self);

    my $digits = $self->param("Digits");

    my $TwiML = qq(
        <Response>
            <Dial callerId="4795217904" action="http://infoservant.com/ivr/voice/dial/action" method="POST">4796298987</Dial>
        </Response>
    );

    $self->render(text => $TwiML);
}

sub dial_helen_medley {
    my $self = shift;

    save_params($self);

    my $digits = $self->param("Digits");

    # <Dial callerId="4795217904" action="http://infoservant.com/ivr/voice/dial/action" method="POST">4796298988</Dial>
    # <Dial callerId="4795217904" action="http://infoservant.com/ivr/voice/dial/action" method="POST">4796298987</Dial>

    my $TwiML = qq(
        <Response>
            <Dial>
                <Conference beep="true" hangupOnStar="true" maxParticipants="5">
                    4795217904
                </Conference>
            </Dial>
        </Response>
    );

    $self->render(text => $TwiML);
}

sub speak {
    my $self = shift;

    save_params($self);

    my $words = $self->param("words");
    $words = Mojo::Util::url_unescape($words);

    my $TwiML = qq(
        <Response>
            <Say>$words</Say>
        </Response>
    );

    save_xml($self, $TwiML);

    $self->render(text => $TwiML);
}

sub action_call {
    my $self = shift;

    save_params($self);

    $self->render(data => "");
}

sub heartbeat {
    my $self = shift;

    save_params($self);

    $self->render(data => "");
}

sub fallback {
    my $self = shift;

    save_params($self);

    my $TwiML = qq(
        <Response>
            <Say>We are sorry.  An error occurred.  Please call 1-800-555-1212 for assistance.</Say>
        </Response>
    );

    $self->render(text => $TwiML);
}

sub cb_status {
    my $self = shift;

    save_params($self);

    $self->render(data => "");
}

sub verify_pin {
    my $self = shift;

    save_params($self);

    my $TwiML = ""; 
    my @actions = ();

    if ("5239" eq $self->param("Digits")) {
        push(@actions, "<Gather action='http://infoservant.com/ivr/voice/record_greeting' method='POST' numDigits='1'>");
        push(@actions, "<Say>Press one to record your greeting.</Say>");
        push(@actions, "</Gather>");
    }
    else {
        push(@actions, "<Say>Incorrect pin.</Say>");
    }

    my $actions = join("\n", @actions);

    $TwiML = qq(
        <Response>
            $actions
            <Hangup />
        </Response>
    );

    $self->render(text => $TwiML);
}

sub record_greeting
{
    my $self = shift;

    save_params($self);

    my $TwiML = ""; 
    my @actions = ();

    if ("1" eq $self->param("Digits")) {
        push(@actions, qq(<Say>To finish the recording press pound.</Say>));
        push(@actions, qq(<Record playBeep=true action="http://infoservant.com/ivr/voice/save_greeting" method="POST" finishOnKey="#" />));
    }
    else {
        push(@actions, "<Say>Sorry.</Say>");
    }

    my $actions = join("\n", @actions);

    $TwiML = qq(
        <Response>
            $actions
            <Hangup />
        </Response>
    );

    $self->render(text => $TwiML);
}

sub save_greeting
{
    my $self = shift;

    save_params($self);

    my $TwiML = ""; 
    my @actions = ();

    push(@actions, "<Say>Thank you.</Say>");

    my $actions = join("\n", @actions);

    $TwiML = qq(
        <Response>
            $actions
            <Hangup />
        </Response>
    );

    $self->render(text => $TwiML);
}

sub mobile_auth {
    my $self = shift;

    save_params($self);

    my $token = `/usr/bin/php /opt/infoservant.com/bin/php_capability.php`;
    chomp($token);

    $self->render(text => $token);
}

sub receive_mobile {
    my $self = shift;

    save_params($self);

    my $forwarded_from = $self->param("ForwardedFrom");
    my $account_sid = $self->param("AccountSid");
    my $caller = $self->param("Caller");
    my $to = $self->param("PhoneNumber");
    # my $subaccount = SiteCode::DBX->new()->row("select subaccount.* from subaccount where Sid = ?", undef, $account_sid);
    my $account = SiteCode::DBX->new()->row("select account.* from account where AccountSid = ?", undef, $account_sid);
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $$account{id});
    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as internal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $$account{id});

    $caller =~ s/^client:/+1/;
    $to =~ s/^((1)|(\+1))?/+1/;

    my $TwiML = qq(<?xml version="1.0" encoding="UTF-8"?>
        <Response>
            <Dial callerId="$caller" action="http://infoservant.com/voice/cb_dial_mobile" method="POST"> $to </Dial>
        </Response>
    );

    save_xml($self, $TwiML);

    $self->res->headers->content_type('text/xml');
    $self->render(text => $TwiML);
}

1;
