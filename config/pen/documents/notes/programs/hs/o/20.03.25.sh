cd /root/notes;  "o" "#" "<==" "zsh"
cd /root/notes;  "o" "

After something is copied to clipboard (using ctrl+c) I want a script (bash,
python or any other language) to automatically detect that new entry is added to
clipboard, change it's content and put it back to clipboard so when I paste it I
get the modified text. The script should constantly run in background and
monitor the clipboard for changes.

The following script describes the modification that is needed :

Source : " "#" "<==" "o"
cd /root/.pen/documents/notes;  "o" "#" "<==" "zsh"
cd /root/.pen/documents/notes;  "o" "https://www.youtube.com/watch?v=a-0YLT5S0gM" "#" "<==" "o"
