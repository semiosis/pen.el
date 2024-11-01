cd /root/notes;  "docker" "container" "ls" "--filter" "status=running" "--format=[{{ json .Names }},{{json .ID}},{{json .Image}},{{json .Command}},{{json .CreatedAt}},{{json .Status}},{{json .Ports}},{{json .Names}}]" "#" "<==" "sh"
cd /root/notes;  "docker" "container" "ls" "--filter" "status=running" "--format=[{{ json .Names }},{{json .ID}},{{json .Image}},{{json .Command}},{{json .CreatedAt}},{{json .Status}},{{json .Ports}},{{json .Names}}]" "#" "<==" "sh"
cd /root/.pen/documents/notes;  "docker" "container" "ls" "#" "<==" "zsh"
cd /root/.pen/documents/notes;  "docker" "image" "ls" "#" "<==" "zsh"
