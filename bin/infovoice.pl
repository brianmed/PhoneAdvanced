#!/opt/perl

use strict;
use warnings;

use FindBin; 
use lib "$FindBin::Bin/../docroot/info_servant/lib";

use SiteCode::DBX;
use SiteCode::Twilio;
use Sys::Syslog;
use Mojo::Util;

MAIN:
{
    my $dbx = SiteCode::DBX->new();

    while (1) {
        info("Looking for an infovoice.");
        my $infovoice = $dbx->row("SELECT infovoice.* FROM infovoice WHERE status IN ('NOTSTARTED', 'STARTED')", undef);

        if ($infovoice) {
            info(%{ $infovoice });
            $dbx->do("update infovoice set status = 'STARTED' WHERE id = ?", undef, $$infovoice{id});
            my $numbers = $dbx->array("SELECT infovoice_nbr.* FROM infovoice_nbr WHERE infovoice_id = ?", undef, $$infovoice{id});

            foreach my $nbr (@{ $numbers }) {
                info(%{ $nbr });
                speak($infovoice, $nbr);
            }

            my $left = $dbx->array("SELECT infovoice_nbr.* FROM infovoice_nbr WHERE infovoice_id = ? AND status != 'DONE'", undef, $$infovoice{id});
            unless (scalar(@{ $left })) {
                $dbx->do("update infovoice set status = 'DONE' WHERE id = ?", undef, $$infovoice{id});
            }
        }

        sleep(30);
    }
}

# OctoCall

sub speak {
    my ($infovoice, $nbr) = @_;

    return if $$nbr{status} && "DONE" eq $$nbr{status};

    my $dbx = SiteCode::DBX->new();

    my $words = Mojo::Util::url_escape($$infovoice{twiml});
    my $twilio = SiteCode::Twilio->new();
    my $internal_nbr = $dbx->col("select int_nbr.number as interal_nbr from user, int_nbr where user.id = int_nbr.user_id AND user.id = ?", undef, $$infovoice{user_id});
    my $num_calls = $$nbr{num_calls};
    if (3 > $num_calls) {
        ++$num_calls;

        $dbx->do("update infovoice_nbr set num_calls = ?, last_call = NOW() WHERE id = ?", undef, $num_calls, $$nbr{id});

        info("CALLING: $$nbr{number} from $internal_nbr");
        my $err = $twilio->speak(user_id => $$infovoice{user_id}, To => $$nbr{number}, From => $internal_nbr, words => $words);
        if (ref($err)) {
            my $xml = $err->[0];
            my $data = XML::Simple::XMLin($xml);
            my $CallSid = $data->{Call}{Sid};
            $dbx->do("update infovoice_nbr set num_calls = ?, last_call = NOW(), CallSid = ?, status = 'DONE' WHERE id = ?", undef, $num_calls, $CallSid, $$nbr{id});
            info("DONE: $$infovoice{id}: $$nbr{number}");
        }
        else {
            info("ERROR: $$nbr{number}: $err");
            $dbx->do("update infovoice_nbr set num_calls = ?, last_call = NOW(), status = 'CALLED' WHERE id = ?", undef, $num_calls, $$nbr{id});
        }

        select(undef, undef, undef, 1.1); # rate limit
    }
    else {
        info("DONE: $$infovoice{id}: $$nbr{number}: NUM_CALLS: $num_calls");
        $dbx->do("update infovoice_nbr set status = 'DONE' WHERE id = ?", undef, $$nbr{id});
    }
}

sub info {
    my @printme = @_;

    my $s = join("\t", map({ "%s" } @printme));
    openlog("infovoice", 'cons,pid', 'user');
    syslog('info', $s, @printme);
    closelog();
}
