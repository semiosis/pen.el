" Vim color file
" Name:       inkpot.vim
" Maintainer: Ciaran McCreesh <ciaran.mccreesh@googlemail.com>
" Homepage:   http://github.com/ciaranm/inkpot/
"
" This should work in the GUI, rxvt-unicode (88 colour mode) and xterm (256
" colour mode). It won't work in 8/16 colour terminals.
"
" To use a black background, :let g:inkpot_black_background = 1

set background=dark
let g:inkpot_black_background = 0
hi clear
if exists("syntax_on")
   syntax reset
endif

let colors_name = "inkpot"

" I do not think these functions work very well

" map a urxvt cube number to an xterm-256 cube number
fun! <SID>M(a)
    return strpart("0135", a:a, 1) + 0
endfun

" map an xterm-256 cube number to a urxvt cube number
fun! <SID>N(a)
	if (a:a == 0)
		return 0
	elseif (a:a == 1)
		return 1
	elseif (a:a == 3)
		return 2
	elseif (a:a == 4)
		return 5
endfun

" map a urxvt colour to an xterm-256 colour
fun! <SID>X(a)
    if &t_Co == 88
        return a:a
    else
        if a:a == 8
            return 237
        elseif a:a < 16
            return a:a
        elseif a:a > 79
            return 232 + (3 * (a:a - 80))
        else
            let l:b = a:a - 16
            let l:x = l:b % 4
            let l:y = (l:b / 4) % 4
            let l:z = (l:b / 16)
            return 16 + <SID>M(l:x) + (6 * <SID>M(l:y)) + (36 * <SID>M(l:z))
        endif
    endif
endfun

" map an xterm-256 colour to a urxvt colour
fun! <SID>U(a)
    if &t_Co == 88
        return a:a
    else
        if a:a == 237
            return 8
        elseif a:a < 16
            return a:a
        elseif (a:a + 80) / 3 - 232 > 79
            return (a:a + 80) / 3 - 232
        else
            let l:b = a:a - 16
            let l:x = l:b % 6
            let l:y = (l:b / 6) % 6
            let l:z = (l:b / 36)
            return 16 + <SID>N(l:x) + (4 * <SID>N(l:y)) + (16 * <SID>N(l:z))
        endif
    endif
endfun

if ! exists("g:inkpot_black_background")
    let g:inkpot_black_background = 0
endif

if has("gui_running")
    "if ! g:inkpot_black_background
    "    hi Normal         gui=NONE   guifg=#cfbfad   guibg=#1e1e27
    "else
    "    hi Normal         gui=NONE   guifg=#cfbfad   guibg=#000000
    "endif

    hi CursorLine         guibg=#2e2e37

    hi TabLineFill    gui=NONE   guifg=#cd8b60   guibg=NONE
    hi TabLine        gui=NONE   guifg=#000000   guibg=#ce4e4e
    hi TabLineSel     gui=NONE   guifg=#ff0000   guibg=#ce4e4e
    hi ColorColumn     gui=NONE   guifg=#c080d0   guibg=#111111
    "hi ColorColumn     gui=NONE   guifg=#ce4e4e   guibg=NONE

    hi IncSearch      gui=BOLD   guifg=#303030   guibg=#cd8b60
    hi Search         gui=NONE   guifg=#303030   guibg=#ad7b57
    hi ErrorMsg       gui=BOLD   guifg=#ffffff   guibg=#ce4e4e
    hi WarningMsg     gui=BOLD   guifg=#ffffff   guibg=#ce8e4e
    hi ModeMsg        gui=BOLD   guifg=#7e7eae   guibg=NONE
    hi MoreMsg        gui=BOLD   guifg=#7e7eae   guibg=NONE
    hi Question       gui=BOLD   guifg=#ffcd00   guibg=NONE

    "hi StatusLine     gui=BOLD   guifg=#b9b9b9   guibg=#3e3e5e
    "hi StatusLine     gui=NONE   guifg=#c080d0   guibg=#111111
    hi User1          gui=BOLD   guifg=#00ff8b   guibg=#3e3e5e
    hi User2          gui=BOLD   guifg=#7070a0   guibg=#3e3e5e
    "hi StatusLineNC   gui=NONE   guifg=#b9b9b9   guibg=#3e3e5e
    "hi StatusLineNC   gui=NONE   guifg=#808bed      guibg=#111111
    "hi VertSplit      gui=NONE   guifg=#b9b9b9   guibg=#3e3e5e
    hi VertSplit      gui=NONE   guifg=NONE      guibg=#111111

    " command-line completion
    hi WildMenu       gui=BOLD   guifg=#eeeeee   guibg=#6e6eaf
    "hi WildMenu       gui=BOLD   guifg=NONE   guibg=NONE

    hi MBENormal                 guifg=#cfbfad   guibg=#2e2e3f
    hi MBEChanged                guifg=#eeeeee   guibg=#2e2e3f
    hi MBEVisibleNormal          guifg=#cfcfcd   guibg=#4e4e8f
    hi MBEVisibleChanged         guifg=#eeeeee   guibg=#4e4e8f

    hi DiffText       gui=NONE   guifg=#ffffcd   guibg=#4a2a4a
    hi DiffChange     gui=NONE   guifg=#ffffcd   guibg=NONE
    hi DiffDelete     gui=NONE   guifg=#ffffcd   guibg=NONE
    "hi DiffAdd        gui=NONE   guifg=#ffffcd   guibg=NONE
    "hi DiffAdd        gui=NONE   guifg=NONE   guibg=NONE
    hi DiffAdd        gui=NONE   guifg=NONE   guibg=#111111

    "hi DiffAdd        gui=NONE   guifg=NONE   guibg=#111111
    ""hi DiffChange     gui=NONE   guifg=#ffffcd   guibg=NONE
    "hi DiffChange     gui=NONE   guifg=NONE   guibg=NONE
    "hi DiffDelete     term=reverse cterm=reverse gui=NONE   guifg=NONE   guibg=NONE
    "hi DiffAdd     term=reverse cterm=reverse gui=NONE   guifg=NONE   guibg=NONE
    ""hi DiffDelete     gui=NONE   guifg=#ffffcd   guibg=NONE

    hi Cursor         gui=NONE   guifg=#404040   guibg=#8b8bff
    hi lCursor        gui=NONE   guifg=#404040   guibg=#8fff8b
    hi CursorIM       gui=NONE   guifg=#404040   guibg=#8b8bff

    "hi Folded         gui=NONE   guifg=#cfcfcd   guibg=#4b208f
    "hi FoldColumn     gui=NONE   guifg=#8b8bcd   guibg=#2e2e2e
    hi Folded         gui=NONE   guifg=#444444   guibg=NONE
    hi FoldColumn     gui=NONE   guifg=#8b8bcd   guibg=NONE

    hi Directory      gui=NONE   guifg=#00ff8b   guibg=NONE
    hi LineNr         gui=NONE   guifg=#8b8bcd   guibg=#2e2e2e
    hi NonText        gui=BOLD   guifg=#8b8bcd   guibg=NONE
    hi SpecialKey     gui=BOLD   guifg=#ab60ed   guibg=NONE
    hi Title          gui=BOLD   guifg=#af4f4b   guibg=NONE
    hi Visual         gui=NONE   guifg=#eeeeee   guibg=#4e4e8f

    hi Comment        gui=NONE   guifg=#ffff55
    hi Constant       gui=NONE   guifg=#ffcd8b   guibg=NONE
    hi String         gui=NONE   guifg=#ffcd8b   guibg=#404040
    "hi Error          gui=NONE   guifg=#ffffff   guibg=#6e2e2e
    hi Error          gui=NONE   guifg=#8e4e4e   guibg=#6e2e2e
    hi Identifier     gui=NONE   guifg=#ff8bff   guibg=NONE
    hi Ignore         gui=NONE
    hi Number         gui=NONE   guifg=#f0ad6d   guibg=NONE
    hi SignColumn     gui=NONE   guifg=#f0ad6d   guibg=NONE
    hi PreProc        gui=NONE   guifg=#409090   guibg=NONE
    hi Special        gui=NONE   guifg=#c080d0   guibg=NONE
    hi SpecialChar    gui=NONE   guifg=#c080d0   guibg=#404040
    hi Statement      gui=NONE   guifg=#808bed   guibg=NONE
    hi Todo           gui=BOLD   guifg=#303030   guibg=#d0a060
    hi Type           gui=NONE   guifg=#ff8bff   guibg=NONE
    hi Underlined     gui=BOLD   guifg=#df9f2d   guibg=NONE
    hi TaglistTagName gui=BOLD   guifg=#808bed   guibg=NONE

    hi perlSpecialMatch   gui=NONE guifg=#c080d0   guibg=#404040
    hi perlSpecialString  gui=NONE guifg=#c080d0   guibg=#404040

    hi cSpecialCharacter  gui=NONE guifg=#c080d0   guibg=#404040
    hi cFormat            gui=NONE guifg=#c080d0   guibg=#404040

    hi doxygenBrief                 gui=NONE guifg=#fdab60   guibg=NONE
    hi doxygenParam                 gui=NONE guifg=#fdd090   guibg=NONE
    hi doxygenPrev                  gui=NONE guifg=#fdd090   guibg=NONE
    hi doxygenSmallSpecial          gui=NONE guifg=#fdd090   guibg=NONE
    hi doxygenSpecial               gui=NONE guifg=#fdd090   guibg=NONE
    hi doxygenComment               gui=NONE guifg=#ad7b20   guibg=NONE
    hi doxygenSpecial               gui=NONE guifg=#fdab60   guibg=NONE
    hi doxygenSpecialMultilineDesc  gui=NONE guifg=#ad600b   guibg=NONE
    hi doxygenSpecialOnelineDesc    gui=NONE guifg=#ad600b   guibg=NONE

    if v:version >= 700
        "hi Pmenu          gui=NONE   guifg=#eeeeee   guibg=#4e4e8f
        "hi PmenuSel       gui=BOLD   guifg=#eeeeee   guibg=#2e2e3f
        "hi PmenuSbar      gui=BOLD   guifg=#eeeeee   guibg=#6e6eaf
        "hi PmenuThumb     gui=BOLD   guifg=#eeeeee   guibg=#6e6eaf

        " this is the completion menu
        hi Pmenu          gui=NONE   guifg=NONE   guibg=NONE
        hi PmenuSel       gui=BOLD   guifg=NONE   guibg=NONE
        hi PmenuSbar      gui=BOLD   guifg=NONE   guibg=NONE
        hi PmenuThumb     gui=BOLD   guifg=NONE   guibg=NONE

        hi SpellBad     gui=undercurl guisp=#cc6666
        hi SpellRare    gui=undercurl guisp=#cc66cc
        hi SpellLocal   gui=undercurl guisp=#cccc66
        hi SpellCap     gui=undercurl guifg=#121212  guisp=#d7d75f

        hi MatchParen   gui=NONE      guifg=#00D700   guibg=#005F00

    endif

    " vim-indent-guides bundle
    hi IndentGuidesOdd  gui=NONE   guifg=NONE      guibg=NONE
    hi IndentGuidesEven gui=NONE   guifg=#c080d0   guibg=#111111
else
    "if ! g:inkpot_black_background
    "    exec "hi Normal         cterm=NONE   ctermfg=" . "60" . " ctermbg=" . <SID>X(80)
    "else
    "    exec "hi Normal         cterm=NONE   ctermfg=" . "60" . " ctermbg=" . <SID>X(16)
    "endif
    "exec "hi Normal         cterm=NONE   ctermfg=" . "60" . " ctermbg=NONE"

    "exec "hi CursorLine      cterm=NONE   ctermfg=228 ctermbg=248"
    "exec "hi CursorLine      cterm=NONE   ctermfg=253 ctermbg=" . <SID>X(81)
    "exec "hi CursorLine      cterm=NONE   ctermfg=228 ctermbg=248"
    "exec "hi CursorLine      cterm=NONE   ctermfg=027 ctermbg=248"

    "exec "hi CursorLine      cterm=NONE   ctermbg=" . <SID>X(81)
    hi CursorLine cterm=NONE ctermfg=249 ctermbg=235

    exec "hi TabLineFill    cterm=NONE   ctermfg=" . <SID>X(73) . " ctermbg=" . "NONE"
    exec "hi TabLine        cterm=BOLD   ctermfg=" . <SID>X(16) . " ctermbg=" . <SID>X(48)
    exec "hi TabLineSel     cterm=BOLD   ctermfg=" . <SID>X(1) . " ctermbg=" . <SID>X(48)
    "exec "hi ColorColumn     cterm=NONE   ctermfg=" . <SID>X(27) . " ctermbg=" . "233"
    "exec "hi ColorColumn     cterm=NONE   ctermfg=88                 ctermbg=" . "232"
    exec "hi ColorColumn     cterm=NONE   ctermfg=NONE               ctermbg=" . "232"
    "exec "hi ColorColumn     cterm=NONE   ctermfg=" . <SID>X(48) . " ctermbg=" . "NONE"

    "exec "hi IncSearch      cterm=BOLD   ctermfg=235                ctermbg=" . <SID>X(73)
    "exec "hi Search      cterm=BOLD   ctermfg=087                ctermbg=104"
    exec "hi Search         cterm=NONE   ctermfg=235                ctermbg=" . <SID>X(52)
    "exec "hi IncSearch         cterm=NONE   ctermfg=130                ctermbg=208"
    exec "hi IncSearch         cterm=NONE   ctermfg=208                ctermbg=130"
    exec "hi ErrorMsg       cterm=BOLD   ctermfg=" . <SID>X(16) . " ctermbg=" . <SID>X(48)
    exec "hi WarningMsg     cterm=BOLD   ctermfg=" . <SID>X(16) . " ctermbg=" . <SID>X(68)
    exec "hi ModeMsg        cterm=BOLD   ctermfg=" . <SID>X(38) . " ctermbg=" . "NONE"
    exec "hi MoreMsg        cterm=BOLD   ctermfg=" . <SID>X(38) . " ctermbg=" . "NONE"
    exec "hi Question       cterm=BOLD   ctermfg=" . <SID>X(52) . " ctermbg=" . "NONE"

    "exec "hi StatusLine     cterm=BOLD   ctermfg=" . <SID>X(85) . " ctermbg=" . <SID>X(81)
    " 
    "the nice blue -- removing the syntax highlightingis far too problematic BEST
    "exec "hi StatusLine     cterm=NONE   ctermfg=" . <SID>X(27) . " ctermbg=" . "233"
    "
    "exec "hi StatusLine     cterm=NONE   ctermfg=NONE ctermbg=233"
    "exec "hi StatusLine     cterm=NONE   ctermfg=NONE ctermbg=233"
    exec "hi User1          cterm=BOLD   ctermfg=" . <SID>X(28) . " ctermbg=" . <SID>X(81)
    exec "hi User2          cterm=BOLD   ctermfg=" . <SID>X(39) . " ctermbg=" . <SID>X(81)
    "exec "hi StatusLineNC   cterm=NONE   ctermfg=" . <SID>X(84) . " ctermbg=" . <SID>X(81)

    " need the patch for this to work
    exec "hi QuickFixCurrentLine          cterm=BOLD   ctermfg=NONE ctermbg=NONE"

    "the nice blue -- left -- removing the syntax highlightingis far too problematic BEST
    "exec "hi StatusLineNC   cterm=NONE   ctermfg=" . <SID>X(55) . " ctermbg=" . "233"

    "exec "hi StatusLineNC   cterm=NONE   ctermfg=NONE ctermbg=NONE"
    "exec "hi VertSplit      cterm=NONE   ctermfg=" . <SID>X(84) . " ctermbg=" . <SID>X(81)
    exec "hi VertSplit      cterm=NONE   ctermfg=" . "233" . " ctermbg=" . "233"

    " commandline completion
    exec "hi WildMenu       cterm=BOLD   ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(38)
    "exec "hi WildMenu       cterm=BOLD   ctermfg=NONE               ctermbg=NONE"

    exec "hi MBENormal                   ctermfg=" . <SID>X(85) . " ctermbg=" . <SID>X(81)
    exec "hi MBEChanged                  ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(81)
    exec "hi MBEVisibleNormal            ctermfg=" . <SID>X(85) . " ctermbg=" . <SID>X(82)
    exec "hi MBEVisibleChanged           ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(82)

    "exec "hi DiffText       cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(34)

    "exec "hi DiffChange     cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . "NONE"
    "exec "hi DiffDelete     cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(32)
    "exec "hi DiffAdd        cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(20)
    "exec "hi DiffText       cterm=NONE   ctermfg=" . <SID>X(0) . " ctermbg=34"
    exec "hi DiffText       cterm=NONE   ctermfg=234               ctermbg=40"
    exec "hi DiffChange     cterm=NONE   ctermfg=" . <SID>X(84) . " ctermbg=" . "NONE"
    exec "hi DiffDelete     cterm=NONE   ctermfg=" . <SID>X(81) . " ctermbg=" . "NONE"
    ""exec "hi DiffText       cterm=NONE   ctermfg=234               ctermbg=40"
    ""exec "hi DiffChange     cterm=NONE   ctermfg=" . <SID>X(84) . " ctermbg=" . "NONE"
    ""exec "hi DiffDelete     cterm=NONE   ctermfg=" . <SID>X(81) . " ctermbg=" . "NONE"
    "exec "hi DiffText       term=reverse cterm=reverse   ctermfg=NONE ctermbg=NONE"
    "exec "hi DiffChange     ctermfg=NONE ctermbg=NONE"
    "exec "hi DiffDelete     term=reverse cterm=reverse   ctermfg=NONE ctermbg=NONE"
    "exec "hi DiffAdd        cterm=NONE   ctermfg=40                 ctermbg=" . "NONE"
    "exec "hi DiffAdd        cterm=NONE   ctermfg=NONE               ctermbg=" . "233"
    "exec "hi DiffAdd        cterm=NONE   ctermfg=NONE               ctermbg=" . "232"
    exec "hi DiffAdd        cterm=NONE   ctermfg=40                 ctermbg=" . "NONE"
    ""exec "hi DiffAdd        cterm=NONE   ctermfg=40                 ctermbg=" . "NONE"
    "exec "hi DiffAdd     term=reverse cterm=reverse   ctermfg=NONE ctermbg=NONE"
    "exec "hi DiffAdd        cterm=NONE   ctermfg=NONE               ctermbg=" . "NONE"

    "exec "hi Folded         cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(35)
    "exec "hi FoldColumn     cterm=NONE   ctermfg=" . <SID>X(39) . " ctermbg=" . <SID>X(80)
    exec "hi Folded         cterm=NONE   ctermfg=" . <SID>X(81) . " ctermbg=" . "NONE"
    exec "hi FoldColumn     cterm=NONE   ctermfg=" . <SID>X(39) . " ctermbg=" . "NONE"

    "exec "hi Directory      cterm=NONE   ctermfg=" . <SID>X(28) . " ctermbg=" . "NONE"
    exec "hi Directory      cterm=NONE   ctermfg=NONE               ctermbg=" . "NONE"
    "exec "hi LineNr         cterm=NONE   ctermfg=" . <SID>X(39) . " ctermbg=" . "NONE"
    exec "hi LineNr         cterm=NONE   ctermfg=" . <SID>X(39) . " ctermbg=" . "NONE"
    " :help listchars
    exec "hi NonText        cterm=BOLD   ctermfg=233                ctermbg=" . "NONE"
    " :help listchars
    "exec "hi SpecialKey     cterm=BOLD   ctermfg=" . <SID>X(55) . " ctermbg=" . "NONE"
    exec "hi SpecialKey     cterm=BOLD   ctermfg=235                ctermbg=" . "NONE"
    exec "hi Title          cterm=BOLD   ctermfg=" . <SID>X(48) . " ctermbg=" . "NONE"
    exec "hi Visual         cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(38)
    "exec "hi Visual         cterm=NONE   ctermfg=253 ctermbg=59"

    exec "hi Comment        cterm=NONE   ctermfg=" . "227"
    "exec "hi Comment        cterm=NONE   ctermfg=000              ctermbg=238"
    " exec "hi Comment        cterm=NONE   ctermfg=NONE              ctermbg=NONE"
    exec "hi Constant       cterm=NONE   ctermfg=" . <SID>X(73) . " ctermbg=" . "NONE"
    "exec "hi String         cterm=NONE   ctermfg=" . <SID>X(73) . " ctermbg=" . <SID>X(81)
    exec "hi String         cterm=NONE   ctermfg=181                ctermbg=" . <SID>X(81)
    "exec "hi String         cterm=NONE   ctermfg=138                ctermbg=234"
    "exec "hi Error          cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(32)
    exec "hi Error          cterm=NONE   ctermfg=88                 ctermbg=" . <SID>X(32)
    exec "hi Identifier     cterm=NONE   ctermfg=" . <SID>X(53) . " ctermbg=" . "NONE"
    exec "hi Ignore         cterm=NONE"
    exec "hi Number         cterm=NONE   ctermfg=" . <SID>X(69) . " ctermbg=" . "NONE"
    exec "hi SignColumn     cterm=NONE   ctermfg=" . <SID>X(69) . " ctermbg=" . "NONE"
    exec "hi PreProc        cterm=NONE   ctermfg=" . <SID>X(25) . " ctermbg=" . "NONE"
    exec "hi Special        cterm=NONE   ctermfg=" . <SID>X(55) . " ctermbg=" . "NONE"
    exec "hi SpecialChar    cterm=NONE   ctermfg=" . <SID>X(55) . " ctermbg=" . <SID>X(81)
    exec "hi Statement      cterm=NONE   ctermfg=" . <SID>X(27) . " ctermbg=" . "NONE"
    exec "hi Todo           cterm=BOLD   ctermfg=" . <SID>X(16) . " ctermbg=" . <SID>X(57)
    exec "hi Type           cterm=NONE   ctermfg=" . <SID>X(71) . " ctermbg=" . "NONE"
    exec "hi Underlined     cterm=BOLD   ctermfg=" . <SID>X(77) . " ctermbg=" . "NONE"
    exec "hi TaglistTagName cterm=BOLD   ctermfg=" . <SID>X(39) . " ctermbg=" . "NONE"
    "exec "hi javaScriptBraces cterm=BOLD   ctermfg=2 ctermbg=NONE"
    exec "hi javaScriptLBraces cterm=BOLD   ctermfg=11 ctermbg=4"
    exec "hi javaScriptRBraces cterm=BOLD   ctermfg=4 ctermbg=NONE"
    hi EasyMotionTarget ctermbg=none ctermfg=103
    hi EasyMotionTarget2First ctermbg=none ctermfg=103
    hi EasyMotionTarget2Second ctermbg=none ctermfg=103
    hi EasyMotionShade  ctermbg=none ctermfg=60

    if v:version >= 700
        exec "hi Pmenu          cterm=NONE   ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(82)
        exec "hi PmenuSel       cterm=BOLD   ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(38)
        exec "hi PmenuSbar      cterm=BOLD   ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(39)
        exec "hi PmenuThumb     cterm=BOLD   ctermfg=" . <SID>X(87) . " ctermbg=" . <SID>X(39)

        " this is the completion menu
        exec "hi Pmenu          cterm=NONE   ctermfg=NONE ctermbg=NONE"
        "exec "hi PmenuSel       cterm=BOLD   ctermfg=NONE ctermbg=NONE"
        "exec "hi PmenuSbar      cterm=BOLD   ctermfg=NONE ctermbg=NONE"
        "exec "hi PmenuThumb     cterm=BOLD   ctermfg=NONE ctermbg=NONE"

        "exec "hi SpellBad       cterm=NONE ctermfg=204 ctermbg=160"
        exec "hi SpellBad       cterm=NONE ctermfg=216 ctermbg=160"
        exec "hi SpellRare      cterm=NONE ctermbg=" . <SID>X(33)
        exec "hi SpellLocal     cterm=NONE ctermbg=" . <SID>X(36)
        exec "hi SpellCap       cterm=NONE   ctermfg=" . <SID>X(80) . " ctermbg=185"
        exec "hi MatchParen     cterm=NONE ctermbg=22               ctermfg=40"
    endif

    " vim-indent-guides bundle
    exec "hi IndentGuidesOdd      cterm=NONE   ctermfg=NONE               ctermbg=NONE    "
    exec "hi IndentGuidesEven     cterm=NONE   ctermfg=NONE               ctermbg=" . "233"
endif

"hi Normal       ctermfg=60
"
map <F12> ;call ToggleCommentSyntax()<CR>
" map <S-F12> ;call ToggleCommentSyntax()<CR>

let g:comment_syntax_on = 1
if !exists("*ToggleCommentSyntax")
    function! ToggleCommentSyntax()
        if g:comment_syntax_on == 1
            if has("gui_running")
                hi Comment        gui=NONE   guifg=#111111   guibg=NONE
            else
                exec "hi Comment        cterm=NONE   ctermfg=" . "233" . " ctermbg=NONE"
            endif
            let g:comment_syntax_on = 0
            echom "Hiding comments"
        else
            if has("gui_running")
                hi Comment        gui=NONE   guifg=#ffff55   guibg=NONE
            else
                exec "hi Comment        cterm=NONE   ctermfg=227                ctermbg=" . "NONE"
                "exec "hi Comment        cterm=NONE   ctermfg=000              ctermbg=238"
                " exec "hi Comment        cterm=NONE   ctermfg=NONE              ctermbg=NONE"
            endif
            echom "Revealing comments"
            let g:comment_syntax_on = 1
        endif
    endfunction
endif

" changing the normal highlighting was disabled so it could be colorised
" with nvim
let g:syntax_brightness = 1
map <F11> ;call ToggleBrightness()<CR>
if !exists("*ToggleSyntaxBrightness")
    function! ToggleBrightness()
        if g:syntax_brightness == 1
            hi Normal       ctermfg=103
            exec "hi String         cterm=NONE   ctermbg=" . <SID>X(81)
            "exec "hi String         cterm=NONE   ctermfg=181                ctermbg=" . <SID>X(81)
            let g:syntax_brightness = 2
            echom "Brighter text"
        elseif g:syntax_brightness == 2
            hi Normal       ctermfg=173
            exec "hi String         cterm=NONE   ctermbg=" . <SID>X(81)
            "exec "hi String         cterm=NONE   ctermfg=181                ctermbg=" . <SID>X(81)
            let g:syntax_brightness = 0
            echom "Brighter text"
        else
            hi Normal       ctermfg=60
            exec "hi String         cterm=NONE   ctermbg=234"
            "exec "hi String         cterm=NONE   ctermfg=138                ctermbg=234"
            let g:syntax_brightness = 1
            echom "Darker text"
        endif
    endfunction

    command! ToggleBrightness silent call ToggleBrightness()
endif

" Once is good
ToggleBrightness

" Three times total for dark theme
ToggleBrightness
ToggleBrightness

let g:syntax_on = 1
map <F10> ;call ToggleSyntax()<CR>
if !exists("*ToggleSyntax")
    function! ToggleSyntax()
        if g:syntax_on == 1
            syntax off
            let g:syntax_on = 0
            echom "Syntax off"
        else
            syntax enable
            let g:syntax_on = 1
            echom "Syntax on"
        endif
    endfunction

    command! ToggleSyntax silent call ToggleSyntax()
endif

" For use in vim-easymotion
let g:diff_syntax_on = 1
if !exists("*ToggleDiffSyntax")
    function! DiffSyntaxStatus()
        if g:diff_syntax_on == 1
            echom "Diff Syntax on show whitespace"
        elseif g:diff_syntax_on == 2
            echom "Diff Syntax on ingore whitespace"
        else
            echom "Diff Syntax off"
        endif
    endfunction

    function! ToggleDiffSyntax()
        " too problematic
        exec "hi String         cterm=NONE ctermfg=NONE ctermbg=NONE"
        if g:diff_syntax_on == 0
            set diffopt-=iwhite
            let g:diff_syntax_on = 3
            set hl&
        elseif g:diff_syntax_on == 3
            let g:diff_syntax_on = 1
            set hl+=A:none,C:none,T:none
        elseif g:diff_syntax_on == 1
            set diffopt+=iwhite
            let g:diff_syntax_on = 2
            set hl&
        elseif g:diff_syntax_on == 2
            let g:diff_syntax_on = 0
            set hl+=A:none,C:none,T:none
        else
            " same as 0
            set diffopt-=iwhite
            let g:diff_syntax_on = 1
            set hl&
        endif
    endfunction

    command! ToggleDiffSyntax silent! call ToggleDiffSyntax() \| call DiffSyntaxStatus()
endif

let g:indent_guides_auto_colors = 0
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  cterm=NONE ctermbg=232 ctermfg=232
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  cterm=NONE ctermbg=NONE ctermfg=NONE
"autocmd VimEnter,Colorscheme * :hi IndentGuidesEven cterm=NONE ctermbg=233 ctermfg=233
hi IndentGuidesOdd  cterm=NONE ctermbg=NONE ctermfg=NONE
hi IndentGuidesEven cterm=NONE ctermbg=233 ctermfg=233

hi GrepFile cterm=NONE ctermbg=NONE ctermfg=135
"hi GrepFile cterm=NONE ctermbg=NONE ctermfg=3

hi gitrebaseCommit ctermfg=none

" it's this or /.local.vimrc
hi Number ctermfg=none

hi String ctermfg=none

" or this, as a last resort
fun! DisableColors()
    hi cIncluded ctermfg=none
    hi cCustomClass ctermfg=none
    hi cCustomFunc ctermfg=none
endf

au BufEnter * call DisableColors()

fun! DiffWordSyntax()
    call NumberSyntax()
    hi aa cterm=NONE ctermfg=025 ctermbg=234
    syntax match aa "[^a]\?a[a-z]*"

    hi ee cterm=NONE ctermfg=093 ctermbg=234
    syntax match ee "[^e]\?e[a-z]*"

    hi ii cterm=NONE ctermfg=135 ctermbg=234
    syntax match ii "[^i]\?i[a-z]*"

    hi oo cterm=NONE ctermfg=089 ctermbg=234
    syntax match oo "[^o]\?o[a-z]*"

    hi uu cterm=NONE ctermfg=067 ctermbg=234
    syntax match uu "[^u]\?u[a-z]*"

    "hi aa cterm=NONE ctermfg=033 ctermbg=236
    "syntax match aa "[A-Z]\?a[a-z]*"

    "hi bb cterm=NONE ctermfg=149 ctermbg=236
    "syntax match bb "[A-Z]\?b[a-z]*"

    "hi cc cterm=NONE ctermfg=206 ctermbg=236
    "syntax match cc "[A-Z]\?c[a-z]*"

    "hi dd cterm=NONE ctermfg=227 ctermbg=236
    "syntax match dd "[A-Z]\?d[a-z]*"

    "hi ee cterm=NONE ctermfg=161 ctermbg=236
    "syntax match ee "[A-Z]\?e[a-z]*"

    "hi ff cterm=NONE ctermfg=214 ctermbg=236
    "syntax match ff "[A-Z]\?f[a-z]*"

    "hi gg cterm=NONE ctermfg=075 ctermbg=236
    "syntax match gg "[A-Z]\?g[a-z]*"

    "hi hi cterm=NONE ctermfg=204 ctermbg=236
    "syntax match hh "[A-Z]\?h[a-z]*"

    "hi ii cterm=NONE ctermfg=049 ctermbg=236
    "syntax match ii "[A-Z]\?i[a-z]*"

    "hi jz cterm=NONE ctermfg=149 ctermbg=236
    "syntax match jz "[A-Z]\?[j-z][a-z]*"
endf

"hi Cursor         gui=NONE   ctermfg=040   ctermbg=240
"hi lCursor        gui=NONE   ctermfg=040   ctermbg=240
"hi CursorIM       gui=NONE   ctermfg=040   ctermbg=240

" Remember I also need to change this in syntax.vim
fun! NumberSyntax()
    " real low priority
    syntax match tests '[a-z]\+\([fb]g\)\@='
    syntax match tests '\([fb]g\)\@<=[a-z]\+'

    " underscore
    "syntax match morediscrete "[a-z]\@<=_[a-z]\@="
    "syntax match morediscrete "[A-Z]\@<=_[A-Z]\@="
    "syntax match morediscrete "\c[0-9a-z ]\@<=_\+[0-9a-z]\@="
    " By default it should be discrete
    syntax match morediscrete "_"

    " keep numbers after letters (for units [data and measurements] and
    " ordinal numbers)
    " keep letters before numbers (it's also extremely useful for, for
    " example dates like this 20160818054330UTC. better on than off for
    " sure)
    hi one cterm=NONE ctermfg=033 ctermbg=236
    "syntax match one "\s\?\(\a\d*\)\@<!\(\d*1\)\d\@!\a*\s\?"
    syntax match one "\c[a-f]*\(\d*1\)\d\@!\a*"
    " fails on this .ansi31, so not worth the expense
    "syntax match one "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*1\)\d\@!\a*"
    " for the bash spinner
    syntax match one "\[\@<=\\\]\@="
    syntax match one "\<GPGGA\>"
    " y is done under 'yes'
    " this can mean 10 or a coordinate
    syntax match one "\<[XIVMC]\+I\>"
    syntax match one "\c\<one\>"
    syntax match one "\c(\?\<a)"

    hi two cterm=NONE ctermfg=149 ctermbg=236
    "syntax match two "\(\a\d*\)\@<!\(\d*2\)\d\@!\a*\s\?"
    syntax match two "\c[a-f]*\(\d*2\)\d\@![a-z]*"
    syntax match two "\c[a-z]*\(\d*2\)\d\@![a-z]*\(_t\)\@="
    "syntax match two "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*2\)\d\@!\a*"
    " for the bash spinner
    syntax match two "\[\@<=/\]\@="
    syntax match two "\<GPGSA\>"
    syntax match two "\c\<two\>"
    syntax match two "\c(\?\<b)"

    hi three cterm=NONE ctermfg=206 ctermbg=236
    "syntax match three "\s\?\(\a\d*\)\@<!\(\d*3\)\d\@!\a*\s\?"
    syntax match three "\c[a-f]*\(\d*3\)\d\@![a-z]*"
    "syntax match three "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*3\)\d\@!\a*"
    " for the bash spinner
    syntax match three "\[\@<=|\]\@="
    syntax match three "\<GPGSV\>"
    syntax match three "\c\<z\>"
    syntax match three "\c\<three\>"
    syntax match three "\c(\?\<c)"

    hi four cterm=NONE ctermfg=227 ctermbg=236
    "syntax match four "\s\?\(\a\d*\)\@<!\(\d*4\)\d\@!\a*\s\?"
    syntax match four "\c[a-f]*\(\d*4\)\d\@![a-z]*"
    syntax match four "\c[a-z]*\(\d*4\)\d\@![a-z]*\(_t\)\@="
    "syntax match four "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*4\)\d\@!\a*"
    " for the bash spinner
    syntax match four "\[\@<=-\]\@="
    syntax match four "\<GPRMC\>"
    syntax match four "\c\<four\>"
    syntax match four "\c(\?\<%\@<!d)"

    hi five cterm=NONE ctermfg=161 ctermbg=236
    "syntax match five "\s\?\(\a\d*\)\@<!\(\d*5\)\d\@!\a*\s\?"
    syntax match five "\c\(h[a-f]*\)\@<![a-f]*h\@<!\(\d*5\)\d\@![a-z]*"
    "syntax match five "\c\(h[a-f]*\)\@<!\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*5\)\d\@!\a*"
    syntax match five "\<V\>"
    syntax match five "\<five\>"
    syntax match five "\c(\?\<e)"
    syntax match five "\<[XIVMC]*V\>"

    hi six cterm=NONE ctermfg=214 ctermbg=236
    "syntax match six "\s\?\(\a\d*\)\@<!\(\d*6\)\d\@!\a*\s\?"
    syntax match six "\c[a-f]*\(\d*6\)\d\@![a-z]*"
    syntax match six "\c[a-z]*\(\d*6\)\d\@![a-z]*\(_t\)\@="
    "syntax match six "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*6\)\d\@!\a*"
    syntax match six "\<six\>"
    syntax match six "\c(\?\<f)"
    " this is for functions as they appear in vim's complete menu
    syntax match six " \@<=f \@="

    hi seven cterm=NONE ctermfg=075 ctermbg=236
    "syntax match seven "\s\?\(\a\d*\)\@<!\(\d*7\)\d\@!\a*\s\?"
    syntax match seven "\c[a-f]*\(\d*7\)\d\@![a-z]*"
    "syntax match seven "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*7\)\d\@!\a*"
    syntax match seven "\<seven\>"

    hi eight cterm=NONE ctermfg=204 ctermbg=236
    "syntax match eight "\s\?\(\a\d*\)\@<!\(\d*8\)\d\@!\a*\s\?"
    syntax match eight "\c[a-f]*\(\d*8\)\d\@![a-z]*"
    syntax match eight "\c[a-z]*\(\d*8\)\d\@![a-z]*\(_t\)\@="
    "syntax match eight "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*8\)\d\@!\a*"
    syntax match eight "\<eight\>"
    syntax match eight "\<[XIVMC]*C\>"

    hi nine cterm=NONE ctermfg=049 ctermbg=236
    "syntax match nine "\s\?\(\a\d*\)\@<!\(\d*9\)\d\@!\a*\s\?"
    syntax match nine "\c[a-f]*\(\d*9\)\d\@![a-z]*"
    "syntax match nine "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*9\)\d\@!\a*"
    syntax match nine "\<nine\>"
    syntax match nine "\<[XIVMC]*M\>"

    "hi zero cterm=NONE ctermfg=141 ctermbg=236
    hi zero cterm=NONE ctermfg=127 ctermbg=236
    "syntax match zero "\s\?\(\a\d*\)\@<!\(\d*0\)\d\@!\a*\s\?"
    syntax match zero "\c[a-f]*\(\d*0\)\d\@![a-z]*"
    "syntax match zero "\c\([g-wyz][a-f]\?\)\@<![a-f]*\(\d*0\)\d\@!\a*"
    syntax match zero "zero"
    syntax match zero "\<[XIVMC]*X\>"

    hi onlyhex cterm=NONE ctermfg=149 ctermbg=236
    syntax match onlyhex "\c[a-z0-9]\@<![a-f]\{4,}[a-z0-9]\@!"
    " do not allow be, cd or def
    syntax match onlyhex "\c[a-z0-9]\@<![ae-f]\{2,}[a-z0-9]\@!"
endf

" hi StatusLine StatusLine     xxx term=bold,reverse cterm=bold,reverse gui=bold,reverse
" hi StatusLine term=bold ctermbg=124 ctermfg=052
" hi StatusLine term=NONE ctermbg=232 ctermfg=235
" hi StatusLine term=NONE ctermbg=240 ctermfg=235
" hi StatusLine term=NONE ctermbg=235 ctermfg=232
" hi StatusLine term=NONE ctermbg=012 ctermfg=232
" hi StatusLine term=NONE ctermbg=012 ctermfg=235
hi StatusLine term=NONE cterm=NONE ctermfg=069 ctermbg=234

" hi StatusLine term=reverse ctermbg=232 ctermfg=235

" It doesn't color the command line permanently, which is annoying
" au CmdLineEnter * hi Normal term=bold ctermbg=124 ctermfg=052
" au CmdLineLeave * hi Normal term=bold ctermfg=white ctermbg=000

" vim: set et :
"
" hi Normal term=NONE ctermbg=NONE ctermfg=NONE
