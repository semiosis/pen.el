cd /root/.emacs.d/host/pen.el/scripts;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempaJ1X0P9.txt' | 'pen-fzf' '-q' ''\\\''' > '/root/.pen/tmp/tf_tempYwMgcrC.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_temp1zZHGJN.txt' | eval '/usr/bin/fzf --algo=v2  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | fzf-thing),alt-i:execute-silent(pen-pl {+} | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | fzf-thing),alt-n:execute-silent(pen-pl {+} | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | pen-umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | pen-mnm | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--algo=v2\\\" \\\"--reverse\\\" \\\"--preview=p {} | pen-fzf-scope\\\" \\\"--preview-window=up:30%:hidden\\\"' > '/root/.pen/tmp/tf_templIGFVxG.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempBNj5vFV.txt' | eval '/usr/bin/fzf --algo=v2  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | fzf-thing),alt-i:execute-silent(pen-pl {+} | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | fzf-thing),alt-n:execute-silent(pen-pl {+} | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | pen-umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | pen-mnm | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--algo=v2\\\" \\\"--reverse\\\" \\\"--preview=p {} | pen-fzf-scope\\\" \\\"--preview-window=up:30%:hidden\\\"' > '/root/.pen/tmp/tf_temp9o9fw39.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_temp8xN4Lu2.txt' | 'fzf' '--algo=v2' '-m' '+s' '--reverse' '--preview=p {} | pen-umn | pen-fzf-scope' '--preview-window=up:30%:hidden' > '/root/.pen/tmp/tf_tempkN7Nbb6.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempkS7NnQ8.txt' | 'fzf' '--algo=v2' '-m' '+s' '--reverse' '--preview=p {} | pen-umn | pen-fzf-scope' '--preview-window=up:30%:hidden' > '/root/.pen/tmp/tf_tempZX0idTc.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempZ1S4SJz.txt' | 'fzf' '--algo=v2' '-m' '+s' '--reverse' '--preview=p {} | pen-umn | pen-fzf-scope' '--preview-window=up:30%:hidden' > '/root/.pen/tmp/tf_tempUPLp9tY.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/.emacs.d/host/pen.el/scripts;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempo8nwg1F.txt' | 'fzf' '--algo=v2' '-m' '+s' '--reverse' '--preview=p {} | pen-umn | pen-fzf-scope' '--preview-window=up:30%:hidden' > '/root/.pen/tmp/tf_tempSk8PLoy.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd "/root/.pen/ebooks/J. C. Ryle/Holiness (5)";  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempp1K72PN.txt' | eval '/usr/bin/fzf --algo=v2  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | fzf-thing),alt-i:execute-silent(pen-pl {+} | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | fzf-thing),alt-n:execute-silent(pen-pl {+} | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | pen-umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | pen-mnm | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--no-sort\\\" \\\"-f\\\" \\\"Source Code Retrieval\\\"' > '/root/.pen/tmp/tf_templemYKjD.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/.emacs.d/host/pen.el/src;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_temp6pEfgqe.txt' | 'pen-fzf' '-q' ''\\\''' > '/root/.pen/tmp/tf_tempTHfBQvK.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/.emacs.d/host/pen.el/src;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_temptHuogH3.txt' | 'pen-fzf' '-q' ''\\\''' > '/root/.pen/tmp/tf_tempJr1N1V5.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"
cd /root/notes;  "nvim" "-u" "/root/.nvimrc" "-c" "call TermAndQuit(\" cat '/root/.pen/tmp/tf_tempVXXlh69.txt' | eval '/usr/bin/fzf --algo=v2  --bind=\\\"alt-a:select-all,f1:abort,alt-u:deselect-all,ctrl-k:kill-line,alt-k:jump,tab:toggle-preview,ctrl-alt-f:toggle,alt-z:toggle,ctrl-j:toggle,ctrl-alt-x:up+toggle,ctrl-alt-c:down+toggle,up:up,down:down,ctrl-p:toggle+up,ctrl-n:toggle+down,change:top,alt-t:top,alt-r:execute-silent(pen-pl {+} | awk 1 | head -n 1 | pen-ux drn | pen-tm -f -S -tout spv -xargs ranger),alt-o:execute-silent(pen-pl {+} | awk 1 | head -n 1 | q -l -f | pen-tm -S -tout nw -xargs o),alt-y:toggle-all,alt-g:execute-silent(tmux run -b \\\\\\\\\"pen-tsk M-y M-c M-y; sleep 0.2; unbuffer pen-xc | pen-tv &>/dev/null\\\\\\\\\"),alt-l:execute-silent(pen-pl {+} | pen-tm -f -S -tout spv v),alt-e:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs pin),alt-v:execute-silent(cmd-nice {+} | pen-tm -f -S -tout sps -xargs v),alt-q:execute-silent(cmd-nice {+} | pen-tm -f -S -tout spv -xargs edit-with),alt-s:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d spv -c),alt-h:execute-silent(cmd-nice {+} | pen-umn | head -n 1 | pen-ux drn | xargs pen-tm -d sph -c),alt-w:execute-silent(pen-tm -f -d spv '\\\''v '\\\''),alt-f:execute-silent(pen-pl {+} | fzf-thing),alt-i:execute-silent(pen-pl {+} | awk 1 |  | pen-tm -f -S -i spv -noerror '\\\''pen-mfz -nm'\\\''),alt-p:execute-silent(pen-pl {+} | fzf-thing),alt-n:execute-silent(pen-pl {+} | pen-ux fn | pen-xc),alt-d:execute-silent(pen-pl {+} | awk 1 | xargs -l1 dirname | pen-xc -i -n),alt-c:execute-silent(pen-pl {+} | pen-umn | chomp | sed '\\\''s/\\\\\\\\\"#\\\\\\\\\".*//'\\\'' | sed '\\\''s/#[^#]\\\\\\+$//'\\\'' | sed '\\\''s/\\\\\\s\\\\\\+$//'\\\'' | pen-xc -i -n),alt-m:execute-silent(pen-pl {+} | pen-mnm | chomp | pen-xc -i -n),alt-j:execute-silent(pen-pl {+} | awk 1 |  | head -n 1 | chomp | pen-xc -i)\\\"  \\\"--algo=v2\\\" \\\"--reverse\\\" \\\"--preview=p {} | pen-fzf-scope\\\" \\\"--preview-window=up:30%:hidden\\\"' > '/root/.pen/tmp/tf_templlIXemb.txt'\")" "-c" "call GeneralSyntax()" "-c" "call NumberSyntax()" "-c" "normal\! i" "#" "<==" "pen-nvc"