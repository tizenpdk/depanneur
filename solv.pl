#!/usr/bin/perl
BEGIN {
  my ($wd) = $0 =~ m-(.*)/- ;
  $wd ||= '.';
  unshift @INC,  "$wd/build";
  unshift @INC,  "$wd";
}

use BSSolv;

my $pool = BSSolv::pool->new();
$pool->createwhatprovides();

print $pool;
