#!/usr/bin/perl -w
#
# SMOCK - Simpler Mock
# by Dan Berrange and Richard W.M. Jones.
# Copyright (C) 2008 Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
BEGIN {
  my ($wd) = $0 =~ m-(.*)/- ;
  $wd ||= '.';
  unshift @INC,  "$wd/build";
  unshift @INC,  "$wd";
  unshift @INC,  "$ENV{'VIRTUAL_ENV'}/usr/lib/build"
}

use strict;

use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);
use Build;
use Build::Rpm;
use Data::Dumper;

my $arch = "";
my $chain = 0;
my $dist = "";
my $dryrun = 0;
my $help = 0;
my $keepgoing = 0;
my $localrepo = $ENV{TIZEN_BUILD_ROOT} . "/local/repos";
my $man = 0;
my $overwrite = 0;
my $suffix = "";

GetOptions (
    "arch=s" => \$arch,
    "chain" => \$chain,
    "dist=s" => \$dist,
    "dryrun" => \$dryrun,
    "help|?" => \$help,
    "keepgoing" => \$keepgoing,
    "localrepo=s" => \$localrepo,
    "man" => \$man,
    "overwrite" => \$overwrite,
    "suffix=s" => \$suffix,
    ) or pod2usage (2);
pod2usage (1) if $help;
pod2usage (-exitstatus => 0, -verbose => 2) if $man;

=pod

=head1 NAME

 smock - Simpler mock

=head1 SYNOPSIS

 smock.pl --arch=i386 --arch=x86_64 --distro=fedora-10 list of SRPMs ...

=head1 DESCRIPTION

This is a wrapper around I<mock> which lets you build a whole group of
mutually dependent SRPMs in one go.

The smock command will work out the correct order in which to build
the SRPMs, and makes the result of previous RPM builds available as
dependencies for later builds.

Smock also works incrementally.  It won't rebuild RPMs which were
built already in a previous run, which means if a package fails to
build, you can just fix it and rerun the same smock command.  (In the
unlikely case that you want to force smock to rebuild RPMs then you
must bump the release number or delete the binary RPM from the
localrepo directory).

B<NOTE:> Please read the README file first.  You need to set up mock
and optionally a web server before you can use this command.

=head1 OPTIONS

=over 4

=item B<--arch>

Specify the architecture(s) to build, eg. i386, x86_64.  You can
list this option several times to build several architectures.

=item B<--chain>

Don't run any commands, just print the packages in the correct
format for chain building.  See:
L<http://fedoraproject.org/wiki/Koji/UsingKoji#Chained_builds>

=item B<--distro>

Specify the distribution(s) to build, eg. fedora-9, fedora-10.
You can list this option several times to build several distributions.

=item B<--dryrun>

Don't run any commands, just print the packages in the order
in which they must be built.

=item B<--help>

Print this help.

=item B<--keepgoing>

Don't exit if a package fails, but keep building.

Note that this isn't always safe because new packages may be built
against older packages, in the case where the older package couldn't
be rebuilt because of an error.

However, it is very useful.

=item B<--localrepo>

Local repository.  Defaults to C<$HOME/public_html/smock/yum>

=item B<--man>

Show this help using man.

=item B<--overwrite>

Overwrite existing files that are already in the repository. By default the
build of an SRPM is skipped if there is already a package with the same name,
version and release in the localrepo. With this option, the new build
overwrites the old one. This may lead to unexpected results, if the new build
does not create the same subpackages as the old one, because then the old
subpackages will still be accessible in the repository.

=item B<--suffix>

Append a suffix to the mock configuration file in order to use
a custom one.

=back

=cut

my @packs = @ARGV;

if (0 == @packs) {
    die "specify one or more SRPMs to build on the command line\n"
}

# Resolve the names, dependency list, etc. of the SRPMs that were
# specified.


sub get_lines
{
    local $_;
    open PIPE, "$_[0] |" or die "$_[0]: $!";
    my @lines;
    foreach (<PIPE>) {
        chomp;
        push @lines, $_;
    }
    close PIPE;
    return @lines;
}

my %packs = ();
foreach my $spec (@packs) {
    my $dist="tizen";
    my $archs="i586";
    my $configdir="$ENV{TIZEN_BUILD_ROOT}/obs-configs";
    my $config = Build::read_config_dist($dist, $archs, $configdir);
    #print Dumper($config);
    my $pack = Build::Rpm::parse($config, $spec);
    my $name = $pack->{name};
    my $version = $pack->{version};
    my $release = $pack->{release};
    my @buildrequires = $pack->{deps};
    $packs{$name} = {
        name => $name,
        version => $version,
        release => $release,
        deps => @buildrequires,
        filename => $spec
    }
}

#print Dumper(%packs);

# We don't care about buildrequires unless they refer to other
# packages that we are building.  So filter them on this condition.

sub is_member_of
{
    my $item = shift;

    foreach (@_) {
        return 1 if $item eq $_;
    }
    0;
}

sub dependency_in
{
    my $dep = shift;            # eg. dbus-devel

    while ($dep) {
        return $dep if is_member_of ($dep, @_);
        my $newdep = $dep;
        $newdep =~ s/-\w+$//;   # eg. dbus-devel -> dbus
        last if $newdep eq $dep;
        $dep = $newdep;
    }
    0;
}

foreach my $name (keys %packs) {
    my @buildrequires = @{$packs{$name}->{deps}};
    @buildrequires =
        grep { $_ = dependency_in ($_, keys %packs) } @buildrequires;
    $packs{$name}{deps} = \@buildrequires;
}

# This function takes a list of package names and sorts them into the
# correct order for building, given the existing %packs hash
# containing buildrequires.  We use the external 'tsort' program.

sub tsort
{
    my @names = @_;

    my ($fh, $filename) = tempfile ();

    foreach my $name (@names) {
        my @buildrequires = @{$packs{$name}->{deps}};
        foreach (@buildrequires) {
            print $fh "$_ $name\n"
        }
        # Add a self->self dependency.  This ensures that any
        # packages which don't have or appear as a dependency of
        # any other package still get built.
        print $fh "$name $name\n"
    }
    close $fh;

    get_lines "tsort $filename";
}

# Sort the initial list of package names.

my @names = sort keys %packs;
my @buildorder = tsort (@names);

# With --chain flag we print the packages in groups for chain building.

if ($chain) {
    my %group = ();
    my $name;

    print 'make chain-build CHAIN="';

    foreach $name (@buildorder) {
        my @br = @{$packs{$name}->{deps}};

        # If a BR occurs within the current group, then start the next group.
        my $occurs = 0;
        foreach (@br) {
            if (exists $group{$_}) {
                $occurs = 1;
                last;
            }
        }

        if ($occurs) {
            %group = ();
            print ": ";
        }

        $group{$name} = 1;
        print "$name ";
    }
    print "\"\n";

    exit 0
}

# With --dryrun flag we just print the packages in build order then exit.

if ($dryrun) {
    foreach (@buildorder) {
        print "$_\n";
    }

    exit 0
}

# Now we can build each SRPM.

sub my_mkdir
{
    local $_ = $_[0];

    if (! -d $_) {
        mkdir ($_, 0755) or die "mkdir $_: $!"
    }
}

sub createrepo
{
    my $arch = shift;
    my $dist = shift;

    my_mkdir "$localrepo";
    my_mkdir "$localrepo/$dist";
    my_mkdir "$localrepo/$dist/src";
    my_mkdir "$localrepo/$dist/src/SRPMS";
    system ("cd $localrepo/$dist/src && rm -rf repodata && createrepo -q .") == 0
        or die "createrepo failed: $?\n";

    my_mkdir "$localrepo/$dist/$arch";
    my_mkdir "$localrepo/$dist/$arch/RPMS";
    my_mkdir "$localrepo/$dist/$arch/logs";

    system ("cd $localrepo/$dist/$arch && rm -rf repodata && createrepo -q --exclude 'logs/*rpm' .") == 0
        or die "createrepo failed: $?\n";
}

my @errors = ();

# NB: Need to do the arch/distro in the outer loop to work
# around the caching bug in mock/yum.
        foreach my $name (@buildorder) {
            my $version = $packs{$name}->{version};
            my $release = $packs{$name}->{release};
            my $srpm_filename = $packs{$name}->{filename};

            $release =~ s/\.fc?\d+$//; # "1.fc9" -> "1"

            # Does the built (binary) package exist already?
            my $pattern = "$localrepo/$dist/$arch/RPMS/$name-$version-$release.*.rpm";
            #print "pattern = $pattern\n";
            my @binaries = glob $pattern;

            if (@binaries != 0 && $overwrite) {
                print "*** overwriting $name-$version-$release $arch $dist ***\n";
            }

            if (@binaries == 0 || $overwrite)
            {
                # Rebuild the package.
                print "*** building $name-$version-$release $arch $dist ***\n";

                createrepo ($arch, $dist);

                my $scratchdir = "$ENV{TIZEN_BUILD_ROOT}/local/scratch";

                $ENV{'BUILD_DIR'} = "$ENV{'VIRTUAL_ENV'}/usr/lib/build";
                my $pattern = "$localrepo/$dist/$arch/repodata/*.xml";
                my @repomd = glob $pattern;

                #my $repos = "--repository http://192.168.1.41:82/Tizen:/Base/standard/ ";
                my $repos = "--repository http://download.tz.otcshare.org/live/Tizen:/Base/standard/ ";
                if (@repomd != 0 ) {
                    $repos .= "--rpms $localrepo/$dist/$arch/RPMS ";
                }
                if (system ("sudo BUILD_ROOT=$ENV{TIZEN_BUILD_ROOT}/local/scratch BUILD_DIR=\"$ENV{'VIRTUAL_ENV'}/usr/lib/build\" build --clean --cachedir $ENV{TIZEN_BUILD_ROOT}/local/cache --dist $dist --configdir $ENV{TIZEN_BUILD_ROOT}/obs-configs $repos $srpm_filename") == 0) {
                    # Build was a success so move the final RPMs into the
                    # mock repo for next time.
                    system ("cp $scratchdir/home/abuild/rpmbuild/SRPMS/*.rpm $localrepo/$dist/src/SRPMS") == 0 or die "mv";
                    system ("cp $scratchdir/home/abuild/rpmbuild/RPMS/*/*.rpm $localrepo/$dist/$arch/RPMS") == 0 or die "mv";
                    my_mkdir "$localrepo/$dist/$arch/logs/$name-$version-$release";
                    system ("cp $scratchdir/.build.log $localrepo/$dist/$arch/logs/$name-$version-$release/log") == 0 or die "mv";

                    createrepo ($arch, $dist);

                }
                else {
                    push @errors, "$name-$dist-$arch$suffix";
                    print STDERR "Build failed, return code $?\nLeaving the logs in $scratchdir\n";
                    exit 1 unless $keepgoing;
                }
            }
            else
            {
                print "skipping $name-$version-$release $arch $dist\n";
            }
        }

if (@errors) {
    print "\n\n\nBuild failed for the following packages:\n";
    print "  $_\n" foreach @errors;
    exit 1
}

exit 0
