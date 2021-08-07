(defcustom pen-sh-update nil
  "Export UPDATE=y when executing sn and such"
  :type 'boolean
  :group 'system-custom
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defcustom pen-default-lm-command "openai-complete.sh"
  "Default LM completer script"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-override-lm-command nil
  "Override LM completer script"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-function-prefix "pf-"
  "Prefix string to prepend to prompt function names"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompts-directory (f-join user-emacs-directory "prompts")
  "Personal prompt respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-glossaries-directory (f-join user-emacs-directory "glossaries")
  "Personal glossary respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompts-library-directory (f-join user-emacs-directory "prompts-library")
  "The directory where prompts repositories are stored"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-completers-directory (f-join user-emacs-directory "completers")
  "Directory where personal .completer files are located"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-discovery-recursion-depth 5
  "The number of git repositories deep that pen.el will go looking"
  :type 'integer
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-force-single-collation nil
  "Forcing only one collation will speed up Pen.el"
  :type 'boolean
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-force-few-completions nil
  "Forcing only few completions will speed up Pen.el, but not by much usually"
  :type 'boolean
  :group 'pen
  :initialize #'custom-initialize-default)

(provide 'pen-custom)