# Improved AnsiEsc.vim

This is a [Vim script №302: AnsiEsc.vim](http://www.vim.org/scripts/script.php?script_id=302)
updated to [latest author's version](http://www.drchip.org/astronaut/vim/index.html#ANSIESC)
with several fixes/improvements.

Download .zip/.vmb from http://www.vim.org/scripts/script.php?script_id=4979

## Changes

* updated to latest author's version: **13i** (Apr 02, 2015)
* add support for simple ANSI sequences like "bold" (without defining color)
* add support for 16-color 'light' escape sequences (by Andy Berdan, merged from https://github.com/berdandy/AnsiEsc.vim)
* disable `\swp` and `\rwp` maps if `g:no_plugin_maps` or `g:no_cecutil_maps` exists
* disable DrChip/AnsiEsc menu if `g:no_drchip_menu` or `g:no_ansiesc_menu` exists
* add support for simple ANSI sequences like disable bold/italic/etc.
* minor fixes

## Original README

This is a mirror of http://www.vim.org/scripts/script.php?script_id=302

Files with ANSI escape sequences look good when dumped onto a terminal that accepts them, but have been a distracting clutter when edited via vim.  The AnsiEsc.vim file, when sourced, will conceal Ansi escape sequences but will cause subsequent text to be colored as the escape sequence specifies when used with Vince Negri's conceal patch.  AnsiEsc.vim v3 or later uses the conceal patch to accomplish this.

Without that conceal patch, the best that can be done is to suppress Ansi escape sequences with "Ignore" highlighting.  AnsiEsc.vim v2 does that.

### VIM Developer's Corner:
   
Vince Negri's "conceal" patch to vim6.3 and vim7.0 allows one to suppress strings within a line; ie. in-line folding! This feature is ideal for Ansi escape sequence handling.  Starting with AnsiEsc's version 3 the <AnsiEsc.vim> script makes use of that new capability to display Ansi-sequence containing files.  The Ansi escape sequences themselves are concealed (except for the line where the cursor is), but they have their desired colorizing effect.  Note that you must have Vim7.0 with the +conceal option for the latest <AnsiEsc.vim> (v8) to work.  Apply Vince Negri's patch to the Vim 7.0 source code and compile Vim for "huge" features.  Once you've done that, simply source the <AnsiEsc.vim> file in when you want to see Ansi-escape sequenced text in Vim.

### Typical Compiling Directions:

To use the AnsiEsc v2, just source it in when you wish to; your vim version needs +syntax, which is fairly common.

To use the conceal-mode AnsiEsc (those with versions >= 3), you'll need to have a Vim that has been patched with Vince Negri's concealownsyntax patch; the version will show both +syntax and +conceal.

Typical compiling directions:

* cd ..wherever../vim70/
* browse http://sites.google.com/site/vincenegri/ for the conceal/ownsyntax patch
* patch -p0 < conceal-ownsyntax.diff
* make distclean
* configure --with-features=huge
* make
* make install


(also see: vimtip#1308)
(alpha/beta version available at http://mysite.verizon.net/astronaut/vim/index.html#ANSIESC)

