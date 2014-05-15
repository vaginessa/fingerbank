package lib::merge;

use strict;
use DBI;
use Readonly;
use Data::Dumper;
use utf8;
use HTTP::BrowserDetect;
use autodie;
use Config::IniFiles;


Readonly::Scalar our $DATABASE  => "./result.db";
Readonly::Scalar our $DJANGODB  => "./db.sqlite3";

=item new

Constructor.

=cut

sub new {
    my ( $class, @argv ) = @_;
    my $this = bless {}, $class;

    $this->connect($DATABASE,'orig');
    $this->connect($DJANGODB,'dest');

    return $this;
}

sub connect {
    my($this,$database,$name) = @_;

    my $sqlite = DBI->connect(          
        "dbi:SQLite:dbname=$database", 
        "",
        "",
        { RaiseError => 1}
    ) or die $DBI::errstr;
    $this->{$name} = $sqlite;
}

sub import_fingerprint {
    my($this) =@_;

    my $dest = $this->{'dest'};
    my $orig = $this->{'orig'};
    my $count = '0';
    # dhcp and http 
    my $sth = $orig->prepare( "select  dhcp.hash, http.hash, mac.vendor, dhcp.finger,dhcp.vendor_id, http.user_agent, http.suites, http.uaprof, dhcp.detect from dhcp inner join http on dhcp.mac=http.mac inner join mac on dhcp.mac = mac.mac" );
    $sth->execute();
    
    while (my @data = $sth->fetchrow_array()) {
        my $stx = $dest->prepare( "SELECT http_hash FROM datafinger_fingerprint WHERE http_hash = (?) and dhcp_hash = (?)");
        $stx->execute($data[1],$data[0]);
        if (!$stx->fetchrow_array()) {
            $count++;
            my $browser = HTTP::BrowserDetect->new( $data[5] );
            my $sty = $dest->prepare( "INSERT INTO datafinger_fingerprint (dhcp_hash, http_hash, dhcp_fingerprint, vendor_id, user_agent, suites, uaprof, device_name, is_mac, is_windows, is_unix, is_mobile, is_tablet, os_string) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
            my $user_agent = utf8::encode($data[5]);
            $sty->execute($data[0],$data[1],$data[3],$data[4],$data[5],$data[6],$data[7],$browser->device_name(),$browser->mac(),$browser->windows(),$browser->unix(),$browser->mobile(),$browser->tablet(),$browser->os_string());
        }
    }
    #Only dhcp
    my $sth = $orig->prepare( "SELECT HASH, Finger, Vendor_ID, Computer_name FROM dhcp WHERE dhcp.mac NOT IN (SELECT mac FROM http GROUP BY mac) GROUP BY HASH");
    $sth->execute();
    
    while (my @data = $sth->fetchrow_array()) {
        my $stx = $dest->prepare( "SELECT dhcp_hash FROM datafinger_fingerprint WHERE dhcp_hash = (?)");
        $stx->execute($data[0]);
        if (!$stx->fetchrow_array()) {
            $count++;
            my $sty = $dest->prepare( "INSERT INTO datafinger_fingerprint (dhcp_hash, dhcp_fingerprint, vendor_id, device_name) VALUES (?,?,?,?)");
            $sty->execute($data[0],$data[1],$data[2],$data[3]);
        }
    }
    print $count;
}

sub import_dhcp_class {
    my($this) =@_;

    my $dest = $this->{'dest'};
    my $dhcp_fingerprint_file = 'dhcp_fingerprints.conf';
    my %dhcp_fingerprints;
    tie %dhcp_fingerprints, 'Config::IniFiles', ( -file => $dhcp_fingerprint_file  );

    foreach my $class ( tied(%dhcp_fingerprints)->GroupMembers("class") ) {
        my $class_id = $class;
        $class_id =~ s/^class\s+//;
        my $sty = $dest->prepare( "INSERT INTO datafinger_os_family (id, os_family) VALUES (?,?)");
        $sty->execute($class_id,$dhcp_fingerprints{$class}{"description"});
    }
    foreach my $os ( tied(%dhcp_fingerprints)->GroupMembers("os") ) {
        my $os_id = $os;
        $os_id =~ s/^os\s+//;
        my $os_family = int($os_id / 100);
        my $sty = $dest->prepare( "INSERT INTO datafinger_os_type (id, os_family_id, os_type) VALUES (?,?,?)");
        $sty->execute($os_id,$os_family,$dhcp_fingerprints{$os}{"description"});
    }
}

sub disconnect {
    my($this) = @_;
    my $dest = $this->{'dest'};
    my $orig = $this->{'orig'};
    $dest->disconnect();
    $orig->disconnect;
}

1;
