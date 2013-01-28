package InfoServant::Utils;

use Mojo::Base 'Mojolicious::Controller';

use IPC::Run;
use SiteCode::DBX;
use SiteCode::Twilio;

sub call_nbr {
    my $self = shift;

    if (!$self->session->{account_id}) {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $internal_nbr = SiteCode::DBX->new()->col("select int_nbr.number as interal_nbr from account, int_nbr where account.id = int_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});
    my $external_nbr = SiteCode::DBX->new()->col("select ext_nbr.number as external_nbr from account, ext_nbr where account.id = ext_nbr.account_id AND account.id = ?", undef, $self->session->{account_id});

    my $to = $self->param("call_nbr");
    $self->stash(call_nbr => $to);

    unless ($to) {
        return($self->render());
    }

    my $twilio = SiteCode::Twilio->new();

    $twilio->initiate_web_merge(internal_nbr => $internal_nbr, external_nbr => $external_nbr, to => $to);

    return($self->render());

=for comment
    my @curl = (
        "/usr/bin/curl", 
        "-X",
        "POST",
        "https://api.telapi.com/v1/Accounts/AC600a61c373c34dad9837dd6fb1675b9d/Calls",
        "-u",
        'AC600a61c373c34dad9837dd6fb1675b9d:a23aa7443e9e4d52980f12cfd685f86b',
        "-d",
        "Url=http://infoservant.com/ivr/voice/initiate_web_merge/4795217904/$nbr&From=3609893790&To=4795217904"
    );

    my ($in, $out, $err);
    warn(join(" ", @curl));
    IPC::Run::run([@curl], \$in, \$out, \$err);

    my $xml = $out;

    if ($xml =~ m#<Uri>(/v1/Accounts/\w+/Calls/\w+)</Uri>#ms) {
        my $url = $1;

        sleep(8); # time to answer phone

        my @curl = (
            "/usr/bin/curl", 
            "-X",
            "GET",
            "https://api.telapi.com$url",
            "-u",
            'AC600a61c373c34dad9837dd6fb1675b9d:a23aa7443e9e4d52980f12cfd685f86b',
        );

        my ($in, $out, $err);
        foreach (1 .. 10) {
            warn(join(" ", @curl));
            IPC::Run::run([@curl], \$in, \$out, \$err);

            if ($out =~ m#Status>(.*?)</Status>#) {
                my $status = $1;
                warn("status: $status");
                if ($status =~ m/(completed|failed|busy|no-answer)/) {
                    last;
                }

                if ($status =~ m/in-progress/) {
                    my @curl = (
                        "/usr/bin/curl", 
                        "-X",
                        "POST",
                        "https://api.telapi.com/v1/Accounts/AC600a61c373c34dad9837dd6fb1675b9d/Calls",
                        "-u",
                        'AC600a61c373c34dad9837dd6fb1675b9d:a23aa7443e9e4d52980f12cfd685f86b',
                        "-d",
                        "Url=http://infoservant.com/ivr/voice/dial/web_merge/4795217904/$nbr&From=3609893790&To=$nbr"
                    );

                    warn(join(" ", @curl));
                    IPC::Run::run([@curl], \$in, \$out, \$err);
                    last;
                }
            }
            else {
                warn("Unable to get status");
                last;
            }

            sleep(3);
        }
    }
=cut

    $self->render();
}

1;
