# https://github.com/samrawal/emacs-secondmate/blob/main/emacs/secondmate.py

import requests, sys

url = "localhost:9900"
params = {"text": sys.argv[1:]}
generation = requests.get(url, params).json()["generation"]
print(generation)
