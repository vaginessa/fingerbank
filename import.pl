#/usr/bin/perl


use lib::merge;

my $merge = new lib::merge;
$merge->import_fingerprint;
$merge->disconnect;

