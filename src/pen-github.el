;; v +/"github-search-clone-repo" "$EMACSD/packages27/github-search-20170824.323/github-search.el"
;; github-search-clone-repo

(require 'github-search)

(require 'license-templates)

;; This fixes an issue
(defset github-search-clone-repository-function 'magit-clone-regular)

(defun gh-list-user-repos (account)
  (pen-snc (pen-cmd "gh-list-user-repos" account)))

(defun gh-download-repos-for-user (user)
  (interactive (list (read-string-hist "gh-download-repos-for-user: ")))

  (pen-sps (format "gh-list-user-repos %s | while read line; do gc \"$line\" | cat; done" user)))

(defun gh-search-user-clone-repo (user)
  "Query github using SEARCH-STRING and clone the selected repository."
  (interactive
   (list ;; (read-from-minibuffer "Enter a github user search string: ")
    (read-string-hist "Enter a github user search string: ")))
  (let* ((user (github-search-select-user-from-search-string user))
         (user-repos (github-search-get-repos-from-user-for-completion user)))
    ;; (github-search-select-and-clone-repo-from-repos user-repos)
    (gc (concat "https://github.com/" (fz user-repos)))))

(defun github-search-do-repo-clonef (repo)
  (let ((remote-url (funcall github-search-get-clone-url-function repo))
        (target-directory (github-search-get-target-directory-for-repo repo)))
    (funcall github-search-clone-repository-function remote-url target-directory "")))

(defun pen-egr-guru99 (query)
  (interactive (list (read-string-hist "egr:" "guru99 ")))
  ;; (pen-sps (concat "eww " (pen-q (car (str2list (pen-sn (concat "gl " (pen-q query))))))))
  (eww (car (str2list (pen-sn (concat "gl " (pen-q query)))))))

(defun pen-rat-dockerhub-search (query)
  (interactive (list (read-string-hist "dockerhub:")))
  (pen-sps (concat "rat-dockerhub " (pen-q query))))

(defun pen-k8s-hub-search-eww (query)
  (interactive (list (read-string-hist "egr:" "kubernetes hub ")))
  (pen-sps (concat "eww " (pen-q (car (str2list (pen-sn (concat "gl " (pen-q query) " | grep helm.sh/charts/"))))))))

(defun pen-k8s-hub-search (query)
  (interactive (list (read-string-hist "helm hub install:" "")))
  (fz (str2list (chomp (pen-sn (concat "helm search hub -o json " (pen-q query) " | jq -r '.[].url'"))))
      nil nil "k8s hub: "))

(defun sh/gc (url)
  (interactive (list (read-string-hist "GitHub url:")))
  (term-nsfa-tm (concat "gc " (pen-q url))))

(defun pen-github-docker-compose-search-and-clone (query)
  (interactive (list (read-string-hist "GitHub docker-compose:")))
  (gc (fz (annotate-github-urls-with-info (pen-sn (concat "glh docker-compose " (pen-q query))))
          nil nil "gc docker compose: ")))

(defun pen-github-awesome-search-and-clone (query)
  (interactive (list (read-string-hist "GitHub awesome:")))
  (gc (fz (annotate-github-urls-with-info (pen-sn (concat "glh awesome " (pen-q query))))
          nil nil "gc awesome: ")))

(defun pen-github-example-search-and-clone (query)
  (interactive (list (read-string-hist "GitHub example:")))
  (gc (fz (annotate-github-urls-with-info (pen-sn (concat "glh example " (pen-q query))))
          nil nil "gc example: ")))

(defun github-clone-dired (url)
  (interactive (list (read-string-hist "GitHub url:")))
  (let ((dir (pen-cl-sn (concat "gc " (pen-q url) " | cat") :chomp t)))
    (if (f-directory-p dir)
        (progn
          (dired dir)
          (dired-git-info-mode 1)
          (dired-hide-details-mode 0))
      (message "unsuccesful"))
    dir))
(defalias 'gc 'github-clone-dired)

(defun pen-github-search-and-clone-cookiecutter (query)
  (interactive (list (read-string-hist "cookiecutter query:")))
  (let* ((url (fz (pen-cl-sn (concat "upd glh cookiecutter " (pen-q query) " | cat" ) :chomp t)))
         (dir (if url (gc url)))
         (name (if (and url dir) (read-string-hist "project name: " query))))
    (if (and dir name)
        (term-sps (tmuxify-cmd (concat "CWD= zrepl cookiecutter " (pen-q dir))) (new-project-dir name)))))

(defun zip-shell-filter1 (filtercmd lors)

  ;; -zip-lists
  (let ((l1)
        (l2))
    (if (stringp lors)
        (setq lors (str2list lors)))

    (loop for pen-ux in lors collect
          (list u
                (if (string-match "github.com" u)
                    (concat
                     (pen-snc "get-stars-for-repo" u) "★, " (pen-snc "get-most-recent-commit-for-repo" u))
                  "")))))

(defun annotate-github-urls-with-info (urls)
  (if (stringp urls)
      (setq urls (str2list urls)))

  (loop for pen-ux in urls collect
        (list u
              (if (string-match "github.com" u)
                  (concat
                   (pen-snc "get-stars-for-repo" u) "★, " (pen-snc "get-most-recent-commit-for-repo" u))
                ""))))

(defun test-annotate-github-urls-with-info ()
  (interactive)
  ;; (pen-etv
  ;;  (pps
  ;;   (annotate-github-urls-with-info
  ;;    (list
  ;;     "https://github.com/dinedal/textql"
  ;;     "https://gitlab.com/Oslandia/albion"))))
  (gc
   (fz
    (annotate-github-urls-with-info
     (list
      "https://github.com/dinedal/textql"
      "https://gitlab.com/Oslandia/albion"))
    nil nil "test-annotate-github-urls-with-info: ")))

(defun pen-github-search-and-clone (query)
  (interactive (list (read-string-hist "GitHub query:")))
  (gc (fz (annotate-github-urls-with-info (pen-sn (concat "upd glh " (pen-q query) " | cat")))
          nil nil "gc: ")) :chomp t)

(defun sh/pen-github-search-and-clone (query)
  (interactive (list (read-string-hist "GitHub query:")))
  (sh/gc (fz (annotate-github-urls-with-info (pen-sn (concat "upd glh " (pen-q query)))))))
(defalias 'sh/gc 'sh/pen-github-search-and-clone)

(defun tpb (query)
  (interactive (list (read-string-hist "tpb: ")))
  (pen-sps (concat "tpb " query)))

;; (defun pen-github-search-and-clone-template (query)
;;   (interactive (list (read-string-hist "GitHub query:")))
;;   (term-nsfa-tm (concat "gc " (pen-q (fz (pen-sn (concat "glh " (pen-q query) " template")))))))

(defun pen-github-search-and-clone-template (query)
  (interactive (list (read-string-hist "GitHub query:" (concat (current-lang) " template "))))
  (term-nsfa-tm (concat "gc " (pen-q (fz (pen-sn (concat "glh " query)))))))

;; smth is used for the browse function handler
;; So if pen-i want to add extra stuff I must place it later
(defun chrome (url &optional smth)
  (interactive (list (read-string-hist "chrome url: ")))
  (pen-cl-sn (concat "chrome " (pen-q url)) :detach t))


;; bug
;; It's because of changing buffers
;; (shut-up (substring (pwd) 10))

(defun github-url ()
  (let* ((git-url (str-or (pen-cl-sn "vc url" :dir (pen-pwd) :chomp t))))
    (if git-url
        (if (string-match "//github.com/" git-url)
            git-url))))

(defun vc-url ()
  (str-or (pen-cl-sn "vc url" :dir (pen-pwd) :chomp t)))

(defun chrome-github-actions ()
  "This opens github actions for this git repository in vscode in chrome"
  (interactive)
  (let ((git-url (str-or (pen-cl-sn "vc url" :dir (pen-pwd) :chomp t))))
    (if git-url
        (if (string-match "//github.com/" git-url)
            (progn
              (setq git-url (concat (pen-snc "gh-base-url" git-url) "/actions/new"))
              (chrome git-url))))))

(defun github1s ()
  "This opens the readme of this git repository in vscode in chrome"
  (interactive)
  (let ((git-url (str-or (pen-cl-sn "vc url" :dir (pen-pwd) :chomp t))))
    (if git-url
        (if (string-match "//github.com/" git-url)
            (progn
              (setq git-url (s-replace-regexp "//github\\.com/" "//github1s.com/" git-url))
              (chrome git-url))))))

(defun github-surf ()
  "This opens the readme of this git repository in vscode in chrome"
  (interactive)
  (let ((git-url (str-or (pen-cl-sn "vc url" :dir (pen-pwd) :chomp t))))
    (if git-url
        (if (string-match "//github.com/" git-url)
            (progn
              (setq git-url (s-replace-regexp "//github\\.com/" "//github.surf/" git-url))
              (chrome git-url))))))

(defun chrome-git-url ()
  "This opens this git repository in chrome"
  (interactive)
  (let ((git-url (str-or (pen-cl-sn "vc url" :dir (pen-pwd) :chomp t))))
    (if git-url
        (chrome git-url))))

(provide 'pen-github)
