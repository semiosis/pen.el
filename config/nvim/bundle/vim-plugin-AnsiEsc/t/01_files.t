#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Slurp qw/read_file write_file/;
use File::Temp 'tempfile';
use Data::Dumper;

my $ANSI_CODESET  = qr/(?:\e\[;*\??(?:\d+(?:;\d+)*)?[A-Za-z])+/;
my $RESET_CODESET = qr/\e\[([;\e\[m]|22|24|25|27|28|39|49|0)+m/;

# Various ANSI reset codes
my %RESETS;
@RESETS{qw/22 24 25 27 28 39 49/} = ();

foreach my $file ($ENV{ANSI_FILES} ? (split ' ', $ENV{ANSI_FILES}||'') : (glob 't/data/files/*.ans*')) {
    my $content           = read_file $file;

    my (undef, $tmp_file) = tempfile;

    system qq{t/bin/vimcat -o "$tmp_file" -u NONE -c 'set t_Co=8 | so plugin/cecutil.vim | so autoload/AnsiEsc.vim | call AnsiEsc#AnsiEsc(0)' "$file" };

    my $vimcat_out = read_file $tmp_file;

    my ($content_pieces, $vimcat_pieces) = normalize($content, $vimcat_out);

    if ($content eq $vimcat_out) {
        pass($file);
    }
    else {
        fail($file);

        # dump a diff by pieces
        my (undef, $content_tmp) = tempfile('content_XXXXX', TMPDIR => 1);
        my (undef, $vimcat_tmp)  = tempfile('vimcat_XXXXX',  TMPDIR => 1);

        local $Data::Dumper::Useqq = 1;
        write_file $content_tmp, Dumper($content_pieces);
        write_file $vimcat_tmp,  Dumper($vimcat_pieces);

        system "t/bin/colordiff -u $content_tmp $vimcat_tmp";
    }
}

done_testing;

sub normalize {
    my ($content, $vimcat_out) = (\$_[0], \$_[1]);

    # strip trailing reset ansi codes (from line ends as well)
    s/${RESET_CODESET}$//mg foreach $$content, $$vimcat_out;

    # strip CRs
    y/\r//d                foreach $$content, $$vimcat_out;

    if ((not exists $ENV{NORMALIZE_WHITESPACE}) || $ENV{NORMALIZE_WHITESPACE} != 0) {
        $$_ =~ s/\s+/ /g, $$_ =~ s/\n//g for $content, $vimcat_out;
    }

    my @content_pieces = grep { $_ ne '' } split /($ANSI_CODESET)/, $$content;
    my @vimcat_pieces  = grep { $_ ne '' } split /($ANSI_CODESET)/, $$vimcat_out;

    ($$content, $$vimcat_out) = ('', '');

    my (@content_pieces_normalized, @vimcat_pieces_normalized);

    my ($i, $j) = (0, 0);

    while ($i < @content_pieces) {
        if (($content_pieces[$i]||'') =~ /^\e\[/ && ($vimcat_pieces[$j]||'') =~ /^\e\[/) {
            my $content_piece = $content_pieces[$i];
            my $vimcat_piece  = $vimcat_pieces[$j];

            my @content_codes = $content_piece =~ /\d+/g;
            my @vimcat_codes  = $vimcat_piece  =~ /\d+/g;

            my (%content_codes, %vimcat_codes);
            @content_codes{@content_codes} = ();
            @vimcat_codes{@vimcat_codes}   = ();

            # remove any reset codes from vimcat codes that are not in
            # content
            foreach my $reset (keys %RESETS) {
                if ((not exists $content_codes{$reset}) && exists $vimcat_codes{$reset}) {
                    delete $vimcat_codes{$reset};
                }
            }

            # put back sorted codes
            $content_piece = "\e[" . (join ';', sort { $a <=> $b } keys %content_codes) . 'm';
            $vimcat_piece  = "\e[" . (join ';', sort { $a <=> $b } keys %vimcat_codes)  . 'm';

            push @content_pieces_normalized, $content_piece;
            push @vimcat_pieces_normalized,  $vimcat_piece;

            $$content    .= $content_piece;
            $$vimcat_out .= $vimcat_piece;
        }
        else {
            # mismatch, skip ahead one piece and keep trying
            $$content    .= $content_pieces[$i]||'';
            $$vimcat_out .= $vimcat_pieces[$j]||'';

            push @content_pieces_normalized, $content_pieces[$i]||'';
            push @vimcat_pieces_normalized,  $vimcat_pieces[$j]||'';
        }

        $i++; $j++;

        # scan ahead to next part that has codes
        # assume the codeset positions match
        foreach my $set ([\$i, \@content_pieces, $content,    \@content_pieces_normalized],
                         [\$j, \@vimcat_pieces,  $vimcat_out, \@vimcat_pieces_normalized]) {
            my ($i, $arr, $text, $pieces) = @$set;

            while ($$i < @$arr && $arr->[$$i] !~ /^\e\[/) {
                $$text .= $arr->[$$i];
                push @$pieces, $arr->[$$i];
                $$i++;
            }
        }
    }

    return (\@content_pieces_normalized, \@vimcat_pieces_normalized);
}
