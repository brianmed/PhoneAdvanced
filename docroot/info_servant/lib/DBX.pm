package DBX;

use Moose;
use namespace::autoclean;
use DBI;

use FindBin;

has 'dbdsn' => ( isa => 'Str', is => 'ro', default => "dbi:SQLite:dbname=$FindBin::Bin/../data/InfoServant.db" );
has 'dbh' => ( isa => 'DBI::db', is => 'ro', lazy => 1, builder => '_build_dbh' );

sub _build_dbh {
    my $self = shift;

    return DBI->connect_cached($self->dbdsn(), "", "", { RaiseError => 1, AutoCommit => 1 });
}

sub do {
    my $self = shift;
    my $sql = shift;
    my $attrs = shift;
    my @vars = @_;

    if (ref($self)) {
        return($self->dbh()->do($sql, $attrs, @vars));
    }
    else {
        my $dbh = $self->_build_dbh();
        return($dbh->do($sql, $attrs, @vars));
    }
}

sub success {
    my $self = shift;
    my $sql = shift;
    my $attrs = shift;
    my @vars = @_;

    my $ret = $self->dbh()->do($sql, $attrs, @vars);
    if ($ret) {
        return(1);
    }

    return(0);
}

sub col {
    my $self = shift;
    my $sql = shift;
    my $attrs = shift;
    my @vars = @_;

    # warn("sql: $sql");
    # warn("attrs: $attrs");
    # warn("vars: ", join("//", @{ $vars }));
    my $ret = $self->dbh()->selectcol_arrayref($sql, $attrs, @vars);
    if ($ret && $$ret[0]) {
        return($$ret[0]);
    }

    return(undef);
}

sub DEMOLISH {
    my $self = shift;

    $self->dbh()->disconnect();
}

__PACKAGE__->meta->make_immutable;

1;

