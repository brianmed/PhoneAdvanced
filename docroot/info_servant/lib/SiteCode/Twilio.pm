package SiteCode::Twilio;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use SiteCode::DBX;
use LWP::UserAgent;
use HTTP::Request::Common;
use Mojo::Util;
use URI;

use XML::Simple;

=for comment
curl -XPOST https://api.twilio.com/2010-04-01/Accounts/ACb16e6d197e6d314ad6532724a2923403/Calls \
-d "Url=http://infoservant.com/ivr/voice/dial/speak/Hi%2C+how+are+you%3F" \
-d "To=+14795217904" \
-d "From=+14793160438" \
-u 'ACb16e6d197e6d314ad6532724a2923403:6b7dbb53a500cc820fdc909c183793a9'
=cut

sub speak {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find user.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    my $res = $self->DoPOST(
        url => "https://api.twilio.com/2010-04-01/Accounts/$account_sid/Calls",
        content => [ To => $ops{To}, From => $ops{From}, Url => "http://infoservant.com/ivr/voice/dial/speak/$ops{words}" ],
        account_sid => $account_sid,
        auth_token => "6b7dbb53a500cc820fdc909c183793a9",
    ); 
    if ($res->is_success()) {
        return([ $res->content ]);
    }
    else {
        warn($res->status_line);
        warn($res->content);
        return("Unable to speak.\n");
    }
}

sub quick_conference {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find account.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    my $res = $self->DoPOST(
        url => "https://api.twilio.com/2010-04-01/Accounts/$account_sid/Calls",
        content => [ To => $ops{To}, From => $ops{From}, Url => "http://infoservant.com/ivr/voice/dial/quick_conference/$ops{From}" ],
        account_sid => $account_sid,
        auth_token => "6b7dbb53a500cc820fdc909c183793a9",
    ); 
    if ($res->is_success()) {
        return([ $res->content ]);
    }
    else {
        warn($res->status_line);
        warn($res->content);
        return("Unable to start conference.\n");
    }
}

sub validate_number {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find numbers.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    if (!$ops{validate_external}) {
        return("Unable to find validation number.\n");
    }

    my $nbr = $ops{validate_external};
    $nbr =~ s/^((1)|(\+1))?/+1/;

    my $req = &HTTP::Request::Common::POST(
        "https://api.twilio.com/2010-04-01/Accounts/$account_sid/OutgoingCallerIds",
        Content_Type => 'form-data',
        Content => 
        [ 
            PhoneNumber => $nbr,
            StatusCallback => "http://infoservant.com/ivr/voice/cb_verify",
        ] 
    );

    my $auth_token = "6b7dbb53a500cc820fdc909c183793a9";

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, $auth_token);
    warn("POST Twilio: https://api.twilio.com/2010-04-01/Accounts/$account_sid/IncomingPhoneNumbers/Local (PhoneNumber => $nbr)");
    my $res = $ua->request($req);
    if ($res->is_success()) {
        my $xml = $res->content();
        my $data = XML::Simple::XMLin($xml);
        my $code = $data->{ValidationRequest}{ValidationCode};
        warn(qq(return("validation: $code")));
        return("validation: $code");
    }
    else {
        my $xml = $res->content();
        my $data = XML::Simple::XMLin($xml);
        my $msg = $data->{RestException}{Message};
        if ($msg eq "Phone number is already verified.") {
            return($msg);
        }
        warn($res->status_line . " " . $msg);
        warn($req->as_string());
        return("Unable verify number.\n");
    }
}

sub DoPOST
{
    my $self = shift;
    my %ops = @_;
    my $url = $ops{url};
    my $content = $ops{content};
    my $account_sid = $ops{account_sid};
    my $auth_token = $ops{auth_token};

    my $req = &HTTP::Request::Common::POST(
        $url,
        Content_Type => 'form-data',
        Content => $content,
    );

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, $auth_token);
    warn("POST Twilio: $url");
    # warn("REQ Twilio: $url: " . $req->as_string());
    my $res = $ua->request($req);

    return($res);
}

sub assign_number {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find user.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    if (!$ops{select_int_nbr}) {
        return("Unable to find local number.\n");
    }

    my $res = $self->DoPOST(
        url => "https://api.twilio.com/2010-04-01/Accounts/$account_sid/IncomingPhoneNumbers/Local",
        content => [ PhoneNumber => $ops{select_int_nbr}, VoiceApplicationSid => "AP4427106f1d6e386bb2c2a6cfbc20b7e5" ],
        account_sid => $account_sid,
        auth_token => "6b7dbb53a500cc820fdc909c183793a9",
    ); 
    if ($res->is_success()) {
        my $xml = $res->content();
        my $data = XML::Simple::XMLin($xml);
        my $sid = $data->{IncomingPhoneNumber}{Sid};

        SiteCode::DBX->new()->do("INSERT INTO int_nbr (account_id, number, Sid) VALUES (?, ?, ?)", undef, $ops{account_id}, $ops{select_int_nbr}, $sid);
        return("");
    }
    else {
        warn($res->status_line);
        return("Unable to assign number.\n");
    }
}

sub delete_recording {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find user.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    my $recording_sid = $ops{recording_sid};
    unless ($recording_sid) {
        return("Unable to find record.\n");
    }

    my $url = URI->new("https://api.twilio.com/2010-04-01/Accounts/$account_sid/Recordings/$recording_sid");
    my $req = HTTP::Request->new(
        DELETE => $url->as_string(),
    );
    warn("DELETE Twilio: " . $url->as_string());

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, "6b7dbb53a500cc820fdc909c183793a9");
    my $res = $ua->request($req);
    if (204 == $res->code()) {
        return("");
    }
    else {
        warn($res->status_line);
    }

    return("Unable to delete recording.");
}

sub retrieve_numbers {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find numbers.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    my $url = URI->new("https://api.twilio.com/2010-04-01/Accounts/$account_sid/IncomingPhoneNumbers");
    my $req = HTTP::Request->new(
        GET => $url->as_string(),
    );
    warn("GET Twilio: " . $url->as_string());

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, "6b7dbb53a500cc820fdc909c183793a9");
    my $res = $ua->request($req);
    if ($res->is_success()) {
        my $xml = $res->content();
        my $data = XML::Simple::XMLin($xml);

        my $nbrs = $data->{IncomingPhoneNumbers}{IncomingPhoneNumber};

        my @nbrs = ();
        if ("HASH" eq ref($nbrs)) {
                push(@nbrs, { FriendlyName => $nbrs->{FriendlyName}, PhoneNumber => $nbrs->{PhoneNumber} });
        }
        elsif ("ARRAY" eq ref($nbrs)) {
            foreach my $nbr (@{ $nbrs }) {
                push(@nbrs, { FriendlyName => $nbr->{FriendlyName}, PhoneNumber => $nbr->{PhoneNumber} });
            }
        }
        else {
            return("Unable to get phone list.\n");
        }

        return(\@nbrs);
    }

    return("");
}

sub find_numbers {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to find numbers.\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    unless ($account_sid) {
        return("Unable to find account.\n");
    }

    my $url = URI->new("https://api.twilio.com/2010-04-01/Accounts/$account_sid/AvailablePhoneNumbers/US/Local");
    $url->query_form(
            (3 == length($ops{find_zip}) ? "AreaCode" : "InPostalCode") => $ops{find_zip},
    );
    my $req = HTTP::Request->new(
        GET => $url->as_string(),
    );
    warn("GET Twilio: " . $url->as_string());

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, "6b7dbb53a500cc820fdc909c183793a9");
    my $res = $ua->request($req);
    if ($res->is_success()) {
        my $xml = $res->content();
        my $data = XML::Simple::XMLin($xml);

        my $nbrs = $data->{AvailablePhoneNumbers}{AvailablePhoneNumber};

        my @nbrs = ();
        if ("HASH" eq ref($nbrs)) {
                push(@nbrs, { FriendlyName => $nbrs->{FriendlyName}, PhoneNumber => $nbrs->{PhoneNumber} });
        }
        elsif ("ARRAY" eq ref($nbrs)) {
            foreach my $nbr (@{ $nbrs }) {
                push(@nbrs, { FriendlyName => $nbr->{FriendlyName}, PhoneNumber => $nbr->{PhoneNumber} });
            }
        }
        else {
            return("Unable to get phone list.\n");
        }

        return(\@nbrs);
    }

    return("");
}

sub deauthorize_account {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_sid}) {
        return("Unable to find account id.\n");
    }

    my $account = SiteCode::DBX->new()->row("select account.* from account where AccountSid = ?", undef, $ops{account_sid});

    SiteCode::DBX->new()->do("update account set AccountSid = NULL where id = ?", undef, $$account{id});
    SiteCode::DBX->new()->do("delete from int_nbr where account_id = ?", undef, $$account{id});
    SiteCode::DBX->new()->do("delete from ext_nbr where account_id = ?", undef, $$account{id});

    return("");
}

sub authorize_account {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to create account.\n");
    }

    if (!$ops{account_sid}) {
        return("Unable to find account id.\n");
    }

    my $sql = qq(
        update account set AccountSid = ? where id = ?
    );
    SiteCode::DBX->new()->do(
        $sql, undef,
        $ops{account_sid}, $ops{account_id}
    );

    return("");
}

sub create_account {
    my $self = shift;
    my %ops = @_;

    if (!$ops{account_id}) {
        return("Unable to create account\n");
    }

    my $account_sid = SiteCode::DBX->new()->col("select AccountSid from account where account.id = ?", undef, $ops{account_id});
    if ($account_sid) {
        return("Already have an account_sid\n");
    }

    my $req = &HTTP::Request::Common::POST(
        'https://api.twilio.com/2010-04-01/Accounts',
    );

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, "6b7dbb53a500cc820fdc909c183793a9");
    my $res = $ua->request($req);
    unless ($res->is_success()) {
        warn($res->status_line);
        return("Unable to contact phone vendor\n");
    }
    else {
        warn("POST Twilio: https://api.twilio.com/2010-04-01/Accounts");
        my $xml = $res->content();
        my $data = XML::Simple::XMLin($xml);
        my $sql = qq(
            insert into subaccount (account_id, AuthToken, Uri, Sid, AuthorizedConnectApps, AvailablePhoneNumbers, Calls, Conferences, ConnectApps, IncomingPhoneNumbers, Notifications, OutgoingCallerIds, Recordings, Sandbox, SMSMessages, Transcriptions) 
            values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        );
        SiteCode::DBX->new()->do(
            $sql, undef,
            $ops{account_id}, $data->{Account}{AuthToken}, $data->{Account}{Uri}, $data->{Account}{Sid},
            $data->{Account}{SubresourceUris}{AuthorizedConnectApps}, $data->{Account}{SubresourceUris}{AvailablePhoneNumbers}, $data->{Account}{SubresourceUris}{Calls},
            $data->{Account}{SubresourceUris}{Conferences}, $data->{Account}{SubresourceUris}{ConnectApps}, $data->{Account}{SubresourceUris}{IncomingPhoneNumbers},
            $data->{Account}{SubresourceUris}{Notifications}, $data->{Account}{SubresourceUris}{OutgoingCallerIds}, $data->{Account}{SubresourceUris}{Recordings},
            $data->{Account}{SubresourceUris}{Sandbox}, $data->{Account}{SubresourceUris}{SMSMessages}, $data->{Account}{SubresourceUris}{Transcriptions},
        );

        return("");
    }
}

sub initiate_web_merge {
    my $self = shift;
    my %ops = @_;

    my $internal_nbr = $ops{internal_nbr};
    my $external_nbr = $ops{external_nbr};
    my $account_sid = $ops{account_sid};
    my $esc_int = Mojo::Util::url_escape($ops{internal_nbr});
    my $esc_ext = Mojo::Util::url_escape($ops{external_nbr});
    my $esc_to = Mojo::Util::url_escape($ops{to});
    my $words = Mojo::Util::url_escape($ops{words});

    my $record = 0;
    if ($ops{record}) {
        $record = 1;
    }

    if ($words) {
        $words = "/$words";
    }
    else {
        $words = "";
    }
    my $req = &HTTP::Request::Common::POST(
        "https://api.twilio.com/2010-04-01/Accounts/$account_sid/Calls",
        Content_Type => 'form-data',
        Content => 
        [ 
            To => $external_nbr,
            From => $internal_nbr,
            Url => "http://infoservant.com/ivr/voice/dial/web_merge/$esc_ext/$esc_to/$record$words",
            StatusCallback => "http://infoservant.com/ivr/voice/cb_dial",
            Fallback => "http://infoservant.com/ivr/voice/fallback",
        ] 
    );

    my $auth_token = "6b7dbb53a500cc820fdc909c183793a9";

    my $ua = LWP::UserAgent->new();
    $ua->credentials("api.twilio.com:443", "Twilio API", $account_sid, $auth_token);
    my $res = $ua->request($req);
    unless ($res->is_success()) {
        warn($res->status_line);
        return("Unable to contact phone vendor\n");
    }
    else {
        warn("POST Twilio: https://api.twilio.com/2010-04-01/Accounts/$account_sid/Calls");
        warn("POST Twilio: " . $req->as_string());
        return([ $res->content ]);
    }
}

__PACKAGE__->meta->make_immutable;

1;
