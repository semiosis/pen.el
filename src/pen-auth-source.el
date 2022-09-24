(require 'auth-source)

(setq auth-sources
      '("~/.pen/.authinfo" "~/.pen/.authinfo.gpg" "~/.pen/.netrc"
        "~/.authinfo" "~/.authinfo.gpg" "~/.netrc"))

(provide 'pen-auth-source)
