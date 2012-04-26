#!/usr/bin/perl
BEGIN {
  my ($wd) = $0 =~ m-(.*)/- ;
  $wd ||= '.';
  unshift @INC,  "$wd/build";
  unshift @INC,  "$wd";
  unshift @INC,  "$ENV{'VIRTUAL_ENV'}/lib/build"
}

use strict;
use Build;
use Build::Rpm;
use Data::Dumper;
my $dist="tizen";
my $archs="i586";
my $configdir="/home/nashif/localbuild/builder/configs";
my $config = Build::read_config_dist($dist, $archs, $configdir);

my $spec = Build::Rpm::parse($config, $ARGV[0]);
print Dumper($spec);
