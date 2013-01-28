package InfoServant;
use Mojo::Base 'Mojolicious';

use ScotchEgg::Schema;
use SiteCode::Site;

has schema => sub {
    return ScotchEgg::Schema->connect("dbi:Pg:dbname=scotch_egg", "kevin", "the_trinity");
};

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->log->level("debug");

    $self->helper(db => sub { $self->app->schema });

    # Documentation browser under "/perldoc"
    $self->plugin(tt_renderer => {template_options => {CACHE_SIZE => 0}});
    $self->plugin('ParamCondition');
    # $self->plugin('HeaderCondition');
    $self->plugin('ConsoleLogger');

    $self->renderer->default_handler('tt');

    my $site_config = SiteCode::Site->config();
    $self->secret($$site_config{site_secret});

    # Router
    my $r = $self->routes;
    
    # $r->get('/')->to('index#slash');
    $r->get('/')->to(controller => 'index', action => 'slash');
    $r->get('/login')->to(controller => 'index', action => 'login');
    $r->post('/login')->over(params => [qw(login password)])->to(controller => 'index', action => 'login');

    $r->any('/ivr/authorized')->to(controller => 'Phone', action => 'authorized');
    $r->any('/ivr/deauthorize')->to(controller => 'Phone', action => 'deauthorize');

    $r->any('/voice/receive_mobile')->to(controller => 'Phone', action => 'receive_mobile');
    $r->any('/voice/fallback_mobile')->to(controller => 'Phone', action => 'fallback');
    $r->any('/voice/cb_status_mobile')->to(controller => 'Phone', action => 'cb_status');
    $r->any('/voice/cb_dial_mobile')->to(controller => 'Phone', action => 'cb_dial');

    $r->any('/ivr/voice/receive_call')->to(controller => 'Phone', action => 'receive_call');
    $r->any('/ivr/voice/initiate_conference')->to(controller => 'Phone', action => 'initiate_conference');
    $r->any('/ivr/voice/initiate_web_merge/:from/:to/:record')->to(controller => 'Phone', action => 'initiate_web_merge');
    $r->any('/ivr/voice/initiate_web_merge/:from/:to/:record/#words')->to(controller => 'Phone', action => 'initiate_web_merge');
    $r->any('/ivr/voice/fallback')->to(controller => 'Phone', action => 'fallback');
    $r->any('/ivr/voice/cb_verify')->to(controller => 'Phone', action => 'cb_verify');
    $r->any('/ivr/voice/cb_gather')->to(controller => 'Phone', action => 'cb_gather');
    $r->any('/ivr/voice/cb_record')->to(controller => 'Phone', action => 'cb_record');
    $r->any('/ivr/voice/cb_dial')->to(controller => 'Phone', action => 'cb_dial');
    $r->any('/ivr/voice/cb_dial/#cb_sid')->to(controller => 'Phone', action => 'cb_dial');
    $r->any('/ivr/voice/cb_status')->to(controller => 'Phone', action => 'cb_status');
    $r->any('/ivr/voice/heartbeat')->to(controller => 'Phone', action => 'heartbeat');
    $r->any('/ivr/voice/dial/hangup')->to(controller => 'Phone', action => 'hangup');
    $r->any('/ivr/voice/dial/straight_voicemail/:adv_from/:adv_to/:adv_record')->to(controller => 'Phone', action => 'straight_voicemail');
    $r->any('/ivr/voice/dial/web_merge/:adv_from/:adv_to/:adv_record')->to(controller => 'Phone', action => 'web_merge');
    $r->any('/ivr/voice/dial/web_merge/:adv_from/:adv_to/:adv_record/#words')->to(controller => 'Phone', action => 'web_merge');
    $r->any('/ivr/voice/dial/ron_medley')->to(controller => 'Phone', action => 'dial_ron_medley');
    $r->any('/ivr/voice/dial/helen_medley')->to(controller => 'Phone', action => 'dial_helen_medley');
    $r->any('/ivr/voice/dial/action')->to(controller => 'Phone', action => 'action_call');
    $r->any('/ivr/voice/dial/speak/#words')->to(controller => 'Phone', action => 'speak');
    $r->any('/ivr/voice/dial/conference')->to(controller => 'Phone', action => 'conference');
    $r->any('/ivr/voice/dial/quick_conference/:quick_from')->to(controller => 'Phone', action => 'quick_conference');
    $r->any('/ivr/voice/pin/input')->to(controller => 'Phone', action => 'verify_pin');
    $r->any('/ivr/voice/record_greeting')->to(controller => 'Phone', action => 'record_greeting');
    $r->any('/ivr/voice/save_greeting')->to(controller => 'Phone', action => 'save_greeting');

    $r->any('/mobile/auth')->to(controller => 'Phone', action => 'mobile_auth');

    $r->any('/callblast/infovoice/wizard')->to(controller => 'CallBlast', action => 'start_infovoice');
    $r->any('/callblast/octocall/save')->to(controller => 'CallBlast', action => 'start_octocall');

    $r->any('/utils')->to(controller => 'Utils', action => 'call_nbr');
    $r->any('/utils')->over(params => { call_nbr => qr/\w/ })->to(controller => 'Utils', action => 'call_nbr');

    $r->post('/signup')->over(params => {name => qr/\w/, email => qr/\w/, vemail => qr/\w/, password => qr/\w/})->to(controller => 'Signup', action => 'add');
    $r->any('/verify/#email/#verify')->to(controller => 'Signup', action => 'verify');
    $r->any('/verify')->to(controller => 'Signup', action => 'verify');

    $r->post('/signup')->to(controller => 'Signup', action => 'start');
    $r->get('/signup')->to(controller => 'Signup', action => 'start');

    $r->any('/dashboard')->to(controller => 'Dashboard', action => 'show');
    $r->any('/dashboard/html/:page')->to(controller => 'Dashboard', action => 'retrieve_html');
    $r->any('/dashboard/javascript/:page')->to(controller => 'Dashboard', action => 'retrieve_js');
    $r->post('/dashboard/delete/voicemail/:recording_sid')->to(controller => 'Dashboard', action => 'delete_voicemail');
    $r->post('/dashboard/call_nbr')->to(controller => 'Dashboard', action => 'call_nbr');
    $r->post('/dashboard/quick_conference')->to(controller => 'Dashboard', action => 'quick_conference');
    $r->post('/dashboard/upd_profile/:part')->to(controller => 'Dashboard', action => 'upd_profile');
    $r->post('/dashboard/provision')->to(controller => 'Dashboard', action => 'provision');
    $r->any('/logout')->to(controller => 'Dashboard', action => 'logout');

    # $r->get('/')->to(namespace => 'InfoServant::Index', action => 'slash');

    # $r->get('/')->over(host => qr/^cal.infoservant\.com/)->to(namespace => 'Hosting::Cal::Infoservant::Com', action => 'dynamic');
    # $r->get('/file.txt')->over(host => qr/^cal.infoservant\.com/)->to(namespace => 'Hosting::Cal::Infoservant::Com', action => 'static');

    # $r->get('/')->over(host => qr/^infoservant\.net/)->to(namespace => 'Hosting::Infoservant::Net', action => 'dynamic');
    # $r->get('/file.txt')->over(host => qr/^infoservant\.net/)->to(namespace => 'Hosting::Infoservant::Net', action => 'static');

    # $r->get('/')->to(namespace => 'Hosting::Default', action => 'dynamic');
    # $r->get('/file.txt')->to(namespace => 'Hosting::Default', action => 'static');
}

1;
