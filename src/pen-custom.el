(defcustom pen-sh-update nil
  "Export UPDATE=y when executing sn and such"
  :type 'boolean
  :group 'system-custom
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defcustom pen-prompt-function-prefix "pf-"
  "Prefix string to prepend to prompt function names"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-directory user-emacs-directory
  "Directory where .prompt files are located"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-library-dir (concat pen-prompt-directory "/prompts")
  "The directory where prompts repositories are stored"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-discovery-recursion-depth 5
  "The number of git repositories deep that pen.el will go looking"
  :type 'integer
  :group 'pen
  :initialize #'custom-initialize-default)

(provide 'pen-custom)