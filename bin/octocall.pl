#!/opt/perl

use strict;
use warnings;

use FindBin; 
use lib "$FindBin::Bin/../docroot/info_servant/lib";

use SiteCode::DBX;
use SiteCode::Twilio;
use Sys::Syslog;
use Mojo::Util;
use XML::Simple;

MAIN:
{
    my $dbx = SiteCode::DBX->new();

    while (1) {
        info("Looking for an octocall.");
        my $octocall = $dbx->row("SELECT octocall.* FROM octocall WHERE status IN ('NOTSTARTED', 'STARTED')", undef);

        if ($octocall) {
            info("id", $$octocall{id});
            $dbx->do("update octocall set status = 'STARTED' WHERE id = ?", undef, $$octocall{id});
            # my $number = $dbx->row("SELECT octocall_nbr.* FROM octocall_nbr WHERE octocall_id = ?", undef, $$octocall{id});
            my $number = $dbx->row("SELECT octocall.*, octocall_nbr.id as octocall_nbr_id, octocall_nbr.number, octocall_nbr.num_calls, octocall_nbr.CallSid FROM octocall, octocall_nbr WHERE octocall.id = octocall_nbr.octocall_id AND status IN ('NOTSTARTED', 'STARTED') AND octocall_id = ? AND call_status in ('QUEUED', 'INPROGRESS') ORDER BY CallSid DESC", undef, $$octocall{id});
            # SELECT octocall_nbr.* FROM octocall_nbr WHERE octocall_id = ?", undef, $$octocall{id});

            if ($$number{CallSid} && "DONE" ne $$number{call_status}) {
                sleep(1);
                redo;
            }

            info("id", $$number{id}, "octocall_nbr_id", $$number{octocall_nbr_id}) if keys %$number;
            call($octocall, $number) if keys %$number;

            my $left = $dbx->row("SELECT octocall.*, octocall_nbr.id as octocall_nbr_id, octocall_nbr.number, octocall_nbr.num_calls, octocall_nbr.CallSid FROM octocall, octocall_nbr WHERE octocall.id = octocall_nbr.octocall_id AND status IN ('NOTSTARTED', 'STARTED') AND octocall_id = ? AND call_status in ('QUEUED', 'INPROGRESS') ORDER BY CallSid DESC", undef, $$octocall{id});
            unless (keys %$left) {
                $dbx->do("update octocall set status = 'DONE' WHERE id = ?", undef, $$octocall{id});
            }
            else {
                sleep(1);
                redo;
            }
        }

        sleep(30);
    }
}

sub call {
    my ($octocall, $nbr) = @_;

    return if $$nbr{call_status} && "DONE" eq $$nbr{call_status};

    my $dbx = SiteCode::DBX->new();

    my $twilio = SiteCode::Twilio->new();
    my $internal_nbr = $dbx->col("select int_nbr.number as interal_nbr from user, int_nbr where user.id = int_nbr.user_id AND user.id = ?", undef, $$octocall{user_id});
    my $external_nbr = $dbx->col("select ext_nbr.number as external_nbr from user, ext_nbr where user.id = ext_nbr.user_id AND user.id = ?", undef, $$octocall{user_id});
    my $account_sid = $dbx->col("select AccountSid from user where user.id = ?", undef, $$octocall{user_id});
    my $num_calls = $$nbr{num_calls};
    if (3 > $num_calls) {
        ++$num_calls;

        $dbx->do("update octocall_nbr set num_calls = ?, last_call = NOW() WHERE id = ?", undef, $num_calls, $$nbr{octocall_nbr_id});

        info("CALLING: $$nbr{number} from $internal_nbr");
        # screwy logic, sorry
        my $err = $twilio->initiate_web_merge(
            account_sid => $account_sid,
            internal_nbr => $external_nbr,
            external_nbr => $$nbr{number},
            to => $external_nbr,
            record => 0,
            words => $$octocall{greeting},
        );
        if (ref($err)) {
            my $xml = $err->[0];
            my $data = XML::Simple::XMLin($xml);
            my $CallSid = $data->{Call}{Sid};
            $dbx->do("update octocall_nbr set num_calls = ?, last_call = NOW(), CallSid = ?, call_status = 'INPROGRESS' WHERE id = ?", undef, $num_calls, $CallSid, $$nbr{octocall_nbr_id});
            info("DONE: $$octocall{id}: $$nbr{number}");
        }
        else {
            info("ERROR: $$nbr{number}: $err");
            $dbx->do("update octocall_nbr set num_calls = ?, last_call = NOW(), call_status = 'CALLED' WHERE id = ?", undef, $num_calls, $$nbr{octocall_nbr_id});
        }

        select(undef, undef, undef, 1.1); # rate limit
    }
    else {
        info("DONE: $$octocall{id}: $$nbr{number}: NUM_CALLS: $num_calls");
        $dbx->do("update octocall_nbr set call_status = 'DONE' WHERE id = ?", undef, $$nbr{id});
    }
}

sub info {
    my @printme = @_;

    my $s = join("\t", map({ "%s" } @printme));
    openlog("octocall", 'cons,pid', 'user');
    syslog('info', $s, @printme);
    closelog();
}
