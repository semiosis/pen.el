;;; lsp-erlang.el --- Erlang Client settings         -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2023 Roberto Aloi, Alan Zimmerman

;; Author: Roberto Aloi, Alan Zimmerman
;; Keywords: erlang lsp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; lsp-erlang client

;;; Code:

(require 'lsp-mode)
(require 'lsp-semantic-tokens)

(defgroup lsp-erlang nil
  "LSP support for the Erlang programming language.
It can use erlang-ls or erlang-language-platform (ELP)."
  :group 'lsp-mode)

(defgroup lsp-erlang-ls nil
  "LSP support for the Erlang programming language using erlang-ls."
  :group 'lsp-mode
  :link '(url-link "https://github.com/erlang-ls/erlang_ls"))

(defgroup lsp-erlang-elp nil
  "LSP support for the Erlang programming language using erlang-language-platform (ELP)."
  :group 'lsp-mode
  :link '(url-link "https://github.com/WhatsApp/erlang-language-platform"))

(defgroup lsp-erlang-elp-semantic-tokens nil
  "LSP semantic tokens support for ELP."
  :group 'lsp-erlang-elp
  :link '(url-link "https://github.com/WhatsApp/erlang-language-platform")
  :package-version '(lsp-mode . "8.0.1"))

(defcustom lsp-erlang-server 'erlang-ls
  "Choose LSP server."
  :type '(choice (const :tag "erlang-ls" erlang-ls)
                 (const :tag "erlang-language-platform" erlang-language-platform))
  :group 'lsp-erlang
  :package-version '(lsp-mode . "6.2"))

;; erlang-ls

(defcustom lsp-erlang-ls-server-path
  "erlang_ls"
  "Path to the Erlang Language Server binary."
  :group 'lsp-erlang-ls
  :risky t
  :type 'file)

(defcustom lsp-erlang-ls-server-connection-type
  'stdio
  "Type of connection to use with the Erlang Language Server: tcp or stdio."
  :group 'lsp-erlang-ls
  :risky t
  :type 'symbol)

(defun lsp-erlang-ls-server-start-fun (port)
  "Command to start erlang_ls in TCP mode on the given PORT."
  `(,lsp-erlang-ls-server-path
    "--transport" "tcp"
    "--port" ,(number-to-string port)))

(defun lsp-erlang-ls-server-connection ()
  "Command to start erlang_ls in stdio mode."
  (if (eq lsp-erlang-ls-server-connection-type 'tcp)
      (lsp-tcp-connection 'lsp-erlang-ls-server-start-fun)
    (lsp-stdio-connection `(,lsp-erlang-ls-server-path "--transport" "stdio"))))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-erlang-ls-server-connection)
                  :major-modes '(erlang-mode)
                  :priority -1
                  :server-id 'erlang-ls))


;; erlang-language-platform

(defcustom lsp-erlang-elp-server-command '("elp" "server")
  "Command to start erlang-language-platform."
  :type '(repeat string)
  :group 'lsp-erlang-elp
  :package-version '(lsp-mode . "8.0.0"))

(defcustom lsp-erlang-elp-download-url
  (format "https://github.com/WhatsApp/erlang-language-platform/releases/latest/download/%s"
          (pcase system-type
            ('gnu/linux "elp-linux-otp-26.tar.gz")
            ('darwin "elp-macos-otp-25.3.tar.gz")))
  "Automatic download url for erlang-language-platform."
  :type 'string
  :group 'lsp-erlang-elp
  :package-version '(lsp-mode . "8.0.0"))

(defcustom lsp-erlang-elp-store-path (f-join lsp-server-install-dir
                                                "erlang"
                                                (if (eq system-type 'windows-nt)
                                                    "elp.exe"
                                                  "elp"))
  "The path to the file in which `elp' will be stored."
  :type 'file
  :group 'lsp-erlang-elp
  :package-version '(lsp-mode . "8.0.0"))

(lsp-dependency
 'erlang-language-platform
 `(:download :url lsp-erlang-elp-download-url
             :decompress :targz
             :store-path lsp-erlang-elp-store-path
             :set-executable? t)
 '(:system "elp"))

;; Semantic tokens

;; Modifier faces

(defface lsp-erlang-elp-bound-modifier-face
  '((t :underline t))
  "The face modification to use for bound variables in patterns."
  :group 'lsp-erlang-elp-semantic-tokens)

(defface lsp-erlang-elp-exported-function-modifier-face
  '((t :underline t))
  "The face modification to use for exported functions."
  :group 'lsp-erlang-elp-semantic-tokens)

(defface lsp-erlang-elp-deprecated-function-modifier-face
  '((t :strike-through t))
  "The face modification to use for deprecated functions."
  :group 'lsp-erlang-elp-semantic-tokens)


;; ---------------------------------------------------------------------
;; Semantic token modifier face customization

(defcustom lsp-erlang-elp-bound-modifier 'lsp-erlang-elp-bound-modifier-face
  "Face for semantic token modifier for `bound' attribute."
  :type 'face
  :group 'lsp-erlang-elp-semantic-tokens
  :package-version '(lsp-mode . "8.0.1"))

(defcustom lsp-erlang-elp-exported-function-modifier 'lsp-erlang-elp-exported-function-modifier-face
  "Face for semantic token modifier for `exported_function' attribute."
  :type 'face
  :group 'lsp-erlang-elp-semantic-tokens
  :package-version '(lsp-mode . "8.0.1"))

(defcustom lsp-erlang-elp-deprecated-function-modifier 'lsp-erlang-elp-deprecated-function-modifier-face
  "Face for semantic token modifier for `deprecated_function' attribute."
  :type 'face
  :group 'lsp-erlang-elp-semantic-tokens
  :package-version '(lsp-mode . "8.0.1"))

;; ---------------------------------------------------------------------

(defun lsp-erlang-elp--semantic-modifiers ()
  "Mapping between rust-analyzer keywords and fonts to apply.
The keywords are sent in the initialize response, in the semantic
tokens legend."
  `(
    ("bound" . ,lsp-erlang-elp-bound-modifier)
    ("exported_function" . ,lsp-erlang-elp-exported-function-modifier)
    ("deprecated_function" . ,lsp-erlang-elp-deprecated-function-modifier)))

;; ---------------------------------------------------------------------
;; Client

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection
                   (lambda ()
                     `(,(or (executable-find
                             (cl-first lsp-erlang-elp-server-command))
                            (lsp-package-path 'erlang-language-platform)
                            "elp")
                       ,@(cl-rest lsp-erlang-elp-server-command))))
  :activation-fn (lsp-activate-on "erlang")
  :priority (if (eq lsp-erlang-server 'erlang-language-platform) 1 -2)
  :semantic-tokens-faces-overrides `(:discard-default-modifiers t
                                                                :modifiers
                                                                ,(lsp-erlang-elp--semantic-modifiers))
  :server-id 'elp
  :custom-capabilities `((experimental . ((snippetTextEdit . ,(and lsp-enable-snippet (featurep 'yasnippet))))))
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (lsp-package-ensure 'erlang-language-platform callback error-callback))))

(defun lsp-erlang-switch-server (&optional lsp-server)
  "Switch priorities of lsp servers, unless LSP-SERVER is already active."
  (interactive)
  (let ((current-server (if (> (lsp--client-priority (gethash 'erlang-ls lsp-clients)) 0)
                            'erlang-ls
                          'erlang-language-platform)))
    (unless (eq lsp-server current-server)
      (dolist (server '(erlang-ls erlang-language-platform))
        (when (natnump (setf (lsp--client-priority (gethash server lsp-clients))
                             (* (lsp--client-priority (gethash server lsp-clients)) -1)))
          (message (format "Switched to server %s." server)))))))

(lsp-consistency-check lsp-erlang)

(provide 'lsp-erlang)
;;; lsp-erlang.el ends here
