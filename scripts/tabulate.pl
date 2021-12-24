#!/usr/bin/env perl

use Text::Tabulate;

#print $ARGV[0]
#my $delim = shift

my $delim = $ARGV[0] || "\t";

my $tab = new Text::Tabulate();
# gutter is the min separator. everything else is filled with spaces
$tab->configure(-tab => "$delim", gutter => "\t");

my $str = do { local $/; <STDIN> };
# print "$str"

#my @lines = <>;
# @out = $tab->format (@lines);

@out = $tab->format ($str);
print @out;