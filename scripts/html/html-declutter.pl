#!/usr/bin/perl
# HTML Article declutter
# Daniel Beer <dlbeer@gmail.com>
# 6 Feb 2014
#
# This file is in the public domain.

use strict;
use warnings;
use HTML::TreeBuilder;
use IO::HTML;

# These tags are deemed to be points of decision-making when pruning.
my %BLOCK_TAGS = (
    h1 => 1,
    h2 => 1,
    h3 => 1,
    h4 => 1,
    h5 => 1,
    h6 => 1,
    div => 1,
    section => 1,
    header => 1,
    footer => 1,
    li => 1,
    ul => 1,
    ol => 1,
    dl => 1,
    dt => 1,
    dd => 1
);

########################################################################
# Prune
#
# This is a heavy-handed filter which strips out large chunks of the
# page based on class/id keywords and tag types.
#
# Pruning is top-down.
########################################################################

sub poison {
    my ($id) = @_;

    $id = lc($id || '');

    return 1 if $id =~ /comment/;
    return 1 if $id =~ /^footer/;
    return 1 if $id =~ /login/;
    return 1 if $id =~ /popup/;
    return 1 if $id =~ /promo/;
    return 1 if $id =~ /related/;
    return 1 if $id =~ /share/;
    return 1 if $id =~ /slideshow/;
    return 1 if $id =~ /links/;
    return 1 if $id =~ /sidebar/;
    return 1 if $id =~ /search/;

    return 0;
}

sub should_prune {
    my ($e) = @_;
    my $tag = lc($e->tag);

    return 1 if $tag eq 'script';
    return 1 if $tag eq 'noscript';
    return 1 if $tag eq 'header';
    return 1 if $tag eq 'footer';
    return 1 if $tag eq 'style';
    return 1 if $tag eq 'img';
    return 1 if $tag eq 'nav';

    if ($BLOCK_TAGS{$tag}) {
	return 1 if poison($e->id);
	return 1 if poison($e->attr("class"));
    }

    return 0;
}

sub prune {
    my ($e) = @_;

    if (should_prune($e)) {
	$e->detach;
	$e->delete;
    } else {
	foreach ($e->content_list) {
	    prune($_) if ref $_;
	}
    }
}

########################################################################
# Shake
#
# This filter is a heuristic filter. It examines link density and
# word-counts to try and differentiate link-spam from article content.
#
# It makes these decisions bottom-up, deciding only for tags in
# %BLOCK_TAGS. If it's decided that a subtree should be kept, this
# decision propagates upwards (we can't delete a tree if it contains
# a subtree which we've decided to keep).
#
# Some kinds of tags can confer a blessing on their descendants, which
# prevents removal.
########################################################################

sub sesame {
    my ($id) = @_;

    $id = lc($id || '');

    return 1 if $id =~ /author/;
    return 1 if $id =~ /byline/;

    return 0;
}

sub blessed {
    my ($e) = @_;

    return 1 if lc($e->tag) eq 'a' &&
	($e->attr("rel") || '') eq "author";

    return 1 if sesame($e->attr("id"));
    return 1 if sesame($e->attr("class"));

    return 0;
}

sub word_count {
    my @w = split(/[^0-9A-Za-z]/, $_[0]);
    my $c = 0;

    foreach (@w) {
	$c++ if length($_) > 0;
    }

    return $c;
}

sub shake {
    my ($e, $pstat, $pcontext) = @_;
    my $wc = 0;
    my $tag = lc($e->tag);
    my %context = %{$pcontext || {}};

    my %stat = (
	LinkWords => 0,
	Words => 0,
	Tags => 1,
	Keep => 0
    );

    $context{Link} = 1 if $tag eq 'a';
    $context{Blessed} = 1 if blessed($e);

    foreach ($e->content_list) {
	if (ref $_) {
	    shake($_, \%stat, \%context);
	} else {
	    $stat{$context{Link} ? "LinkWords" : "Words"} += word_count($_);
	}
    }

    $stat{Keep} = 1 if $context{Blessed};

    if (defined($BLOCK_TAGS{$tag})) {
	my $score = $stat{Words} - $stat{LinkWords} * 2 - $stat{Tags};

	$stat{Keep} = 1 if $score >= 0;

	unless ($stat{Keep}) {
	    $e->detach;
	    $e->delete;
	}
    }

    if (defined($pstat)) {
	$pstat->{$_} += $stat{$_} foreach(keys %stat);
    }
}

########################################################################
# Purify
#
# In this filter we flatten the document structure, removing most markup
# and attributes. The text content is kept.
########################################################################

my %PURE_TAGS = (
    'p' => [],
    'pre' => [],
    'br' => [],
    'em' => [],
    'strong' => [],
    'h1' => [],
    'h2' => [],
    'h3' => [],
    'h4' => [],
    'h5' => [],
    'html' => [],
    'body' => [],
    'head' => [],
    'title' => [],
    'meta' => ['http-equiv', 'name', 'content'],
    'li' => [],
    'ol' => [],
    'ul' => [],
    'dl' => [],
    'dt' => [],
    'dd' => [],
    'blockquote' => []
);

sub purify {
    my ($e) = @_;
    my (@children);

    return $e unless ref $e;

    foreach ($e->content_list) {
	push @children, purify($_);
    }

    my $t = lc($e->tag);
    my $atlist = $PURE_TAGS{$t};

    return @children unless defined($atlist);

    my @attrs;
    foreach (@{$atlist}) {
	my $v = $e->attr($_);
	push @attrs, $_, $v if defined($v);
    }

    return () if $t ne 'br' && $#children < 0 && $#attrs < 0;

    my $n = HTML::Element->new($t, @attrs);
    foreach (@children) {
	$n->push_content($_);
    }

    return $n;
}

########################################################################
# Top-level
#
# Read a file, guessing encoding, then prune => shake => purify.
########################################################################

sub add_comment {
    my ($e, $comment) = @_;

    return unless ref($e);

    if (lc($e->tag) eq 'body') {
	my $p = HTML::Element->new("p");

	$p->push_content($comment);
	$e->push_content($p);
	return 1;
    }

    foreach ($e->content_list) {
	return if add_comment($_, $comment);
    }
}

my $filename = shift || die "You must specfy an input file";
my $comment = shift;

$IO::HTML::default_encoding = 'UTF-8';
my $root = HTML::TreeBuilder->new_from_file((IO::HTML::html_file($filename)));

prune $root;
shake $root;

my $clean = purify($root);

add_comment($clean, $comment) if defined($comment);

print $clean->as_HTML;

$clean->delete;
$root->delete;
