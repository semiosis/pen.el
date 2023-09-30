# Don't allow fp in other scripts to change
# } | s uniqnosort | sponge "$fp"

s append-history-file "$HOME/notes2018/programs/hs/cd.sh" "$(pwd)"

#(
#fp="$HOME/notes2018/programs/hs/cd.sh"

#{
#    cat "$fp"
#    pwd
#} | s uniq | sponge "$fp"
#)
 # | s uniq | sponge "$fp"
