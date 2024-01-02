(require 'yatemplate)

(setq yatemplate-dir
      (let ((yatemplate-host-dir (f-join user-emacs-directory "host/pen.el/config/yatemplates"))
            (yatemplate-builtin-dir (f-join user-emacs-directory "pen.el/config/yatemplates"))
            (yatemplate-default-dir (f-join user-emacs-directory "yatemplates")))

        (cond ((f-dir-p yatemplate-host-dir) yatemplate-host-dir)
              ((f-dir-p yatemplate-builtin-dir) yatemplate-builtin-dir)
              (t yatemplate-default-dir))))

(setq yatemplate-ignored-files-regexp "README.*$")

(yatemplate-fill-alist)

(provide 'pen-yatemplate)
