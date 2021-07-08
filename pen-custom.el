(defcustom pen-sh-update ""
  "Export UPDATE=y when executing sn and such"
  :type 'boolean
  :group 'system-custom
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defcustom pen-prompt-directory ""
  "Directory where .prompt files are located"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(provide 'pen-custom)