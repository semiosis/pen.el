#!/usr/bin/env perl

# TODO make an awk version
# Objectives: Use stream editor to pass over matches
# So it won't spawn 1 process per match

# # Cannot use ✓ in the regex because it is used in the placeholder

#sudo cpanm IPC::Open3

# $VAS/projects/scripts/scrape-words-from-string.pl
use strict;
use strict;
use IPC::Open3;
use Getopt::Std;
use utf8;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("r:", \%options);

my $r = '\w+';

if (defined $options{r}) {
    $r = "$options{r}";
}

#print "hi:" . $ARGV[0];
#shift;

my $first = shift;

$| = 1; # make the current file handle (stdout) hot. This has the same effect as disabling buffering
# I CANT use unbuffer

# Can't use this syntax for stdin when I have command-line arguments
#while(<>) {
#    while ($_ =~ /($r)/g) {
#        print "$1\n";
#    }
#}

# my @cmd = ('cat', '-n');

my @cmd = ($first);

sub filter {
    # The regex match
    my $input = shift;

    my $pid = open3 my $stdin, my $stdout, '>&STDERR', @cmd;

    # print $stdin "foo\nbar\n";
    print $stdin "$input";
    close $stdin;

    my $alloutput;
    while (my $line = readline $stdout) {
        $alloutput .= $line;
    }

    waitpid $pid, 0;
    my $exit = $? >> 8;
    # print "exit: $exit\n";

    return $alloutput;
}

foreach my $line ( <STDIN> ) {
    chomp( $line );

    # This repeats the match until there is no change.
    # Probably not what I want.
    # I only want to go over the matches once
    # Do 2 replacements On the first run add placeholders
    # Then remove placeholders
    # Why does this not work? It's matching the placeholder
    # Either make the placeholder obscure enough to not be matched by
    # the regex, or make a regex which does an "AND NOT"
    # True if pattern BAD does not match, but pattern GOOD does:
    # /(?=^(?:(?!BAD).)*$)GOOD/s
    # while ($line =~ s/(?<!__~~~__)($r)/"__~~~__".filter($1)/ge) {
    while ($line =~ s/(?<!✓)($r)/"✓".filter($1)/ge) {
    # print "$line\n";
    }

    $line =~ s/✓//g;
    print "$line\n";

    # print "$line\n";
}

#
# my $pid = open3 my $stdin, my $stdout, '>&STDERR', @cmd;
# print $stdin "foo\nbar\n";
# close $stdin;
# while (my $line = readline $stdout) {
#     print $line;
# }
# waitpid $pid, 0;
# my $exit = $? >> 8;
# print "exit: $exit\n";
