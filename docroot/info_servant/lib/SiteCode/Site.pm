package SiteCode::Site;

use Moose;
use namespace::autoclean;

use ScotchEgg::Schema;

sub config
{
    my $site_rs = ScotchEgg::Schema->resultset("SiteKey");

    my %site = ();

    foreach my $kv ($site_rs->search_related('site_value')) {
        my $key = $kv->site_key->site_key;
        my $value = $kv->site_key->site_value->site_value;

        $site{$key} = $value;
    }

    return(\%site);
}

__PACKAGE__->meta->make_immutable;

1;
