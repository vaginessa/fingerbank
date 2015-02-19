#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    use lib "/usr/local/fingerbank/lib";
}

use fingerbank::DB;

fingerbank::DB::initialize_local;
fingerbank::DB::fetch_upstream;

1;
