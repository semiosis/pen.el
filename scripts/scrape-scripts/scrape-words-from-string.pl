#!/usr/bin/env perl

# $VAS/projects/scripts/scrape-words-from-string.pl
use strict;
use Getopt::Std;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("r:", \%options);

# Filter command to be used as a predicate
my $c = 'cat';

my $r = '\w+';

if (defined $options{r}) {
    $r = "$options{r}";
}

if (defined $options{c}) {
    $c = "$options{c}";
}


# TODO run a filter command $c and iff it gets through, return true.
sub fi {
    system("ns", shift );
    # print "ns:".shift."\n"
}


#print $options{r};
#print $r;
#
#exit 0;

$| = 1; # make the current file handle (stdout) hot. This has the same effect as disabling buffering
# I CANT use unbuffer
while(<>) {
    while ($_ =~ /($r)/g) {
        print "$1\n";
    }
}
