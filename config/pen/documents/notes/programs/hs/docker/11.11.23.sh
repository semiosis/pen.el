cd /root/.pen/documents/notes;  "docker" "container" "ls" "--all" "--format=[{{ json .Names }},{{json .ID}},{{json .Image}},{{json .Command}},{{json .CreatedAt}},{{json .Status}},{{json .Ports}},{{json .Names}}]" "#" "<==" "zsh"