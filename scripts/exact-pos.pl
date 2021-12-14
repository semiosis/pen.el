#!/usr/bin/env perl

$r=$ARGV[0];
shift;

my $quoted=quotemeta($r);

$| = 1; # make the current file handle (stdout) hot. This has the same effect as disabling buffering
# I CANT use unbuffer

while(<>) {
    my $line = $_;
    # print $.,",",$+[0],"\n" if /a/;
    print $. - 1," ",$-[0],"\n" if ($line =~ /$quoted/);
}
