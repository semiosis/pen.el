cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempc4WpFo6.txt' | eval '/usr/bin/fzf --algo=v2  --color=bw  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | umn | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | umn | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | umn | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | umn | fzf-thing),alt-i:execute-silent(pen-pl {+} | umn | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | umn | fzf-thing),alt-n:execute-silent(pen-pl {+} | umn | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | umn | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | umn | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | umn | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--algo=v2\\\" \\\"--reverse\\\" \\\"--preview=p {} | pen-fzf-scope\\\" \\\"--preview-window=up:30%:hidden\\\"' > '/root/.pen/tmp/tf_tempuvrQJJB.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/.pen/documents/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_templeYlf6n.txt' | eval '/usr/bin/fzf --algo=v2  --color=bw  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | umn | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | umn | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | umn | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | umn | fzf-thing),alt-i:execute-silent(pen-pl {+} | umn | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | umn | fzf-thing),alt-n:execute-silent(pen-pl {+} | umn | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | umn | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | umn | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | umn | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--algo=v2\\\" \\\"--reverse\\\" \\\"--preview=p {} | pen-fzf-scope\\\" \\\"--preview-window=up:30%:hidden\\\"' > '/root/.pen/tmp/tf_tempycvXDjV.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /volumes/home/shane/var/smulliga/source/git/acmeism/RosettaCodeData;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" eval 'cat /proc/384646/fd/0 | tee /proc/384646/fd/1 1>&2'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /volumes/home/shane/var/smulliga/source/git/acmeism/RosettaCodeData;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" eval 'cat /proc/385727/fd/0 | tee /proc/385727/fd/1 1>&2'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /volumes/home/shane/var/smulliga/source/git/acmeism/RosettaCodeData;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" eval 'cat /proc/404842/fd/0 | tee /proc/404842/fd/1 1>&2'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /volumes/home/shane/var/smulliga/source/git/acmeism/RosettaCodeData;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" eval 'cat /proc/405818/fd/0 | tee /proc/405818/fd/1 1>&2'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_temp8lIDUDc.txt' | eval '/usr/bin/fzf --algo=v2  --color=bw  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | umn | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | umn | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | umn | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | umn | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | umn | fzf-thing),alt-i:execute-silent(pen-pl {+} | umn | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | umn | fzf-thing),alt-n:execute-silent(pen-pl {+} | umn | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | umn | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | umn | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | umn | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--algo=v2\\\" \\\"--reverse\\\" \\\"--preview=p {} | pen-fzf-scope\\\" \\\"--preview-window=up:30%:hidden\\\"' > '/root/.pen/tmp/tf_tempM6INRys.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" eval 'slmenu'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"