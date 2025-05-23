;;; el-secretario-org-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from el-secretario-org.el

(autoload 'el-secretario-org-make-source "el-secretario-org" "\
QUERY is an arbitrary org-ql query.

FILES is the files to search through.

NEXT-ITEM-HOOK is called on each heading.

KEYMAP is an keymap to use during review of this source.

IDS is a list of IDs of elements that should be added to the list
of queried items.

If SHUFFLE-P is non-nil, shuffle the list of queried items before
reviewing.

If COMPARE-FUN is non-nil, sort the list of queried items using
that function.  Sorting happens after shuffling if SHUFFLE-P is
non-nil.  COMPARE-FUN should take two arguments which are returned
by `el-secretario-org--parse-headline' See
`el-secretario-org-space-compare-le' for an example sorting
function.

TAG-TRANSITIONS is an alist as described by `el-secretario-org--step-tag-transition'.

(fn QUERY FILES &key NEXT-ITEM-HOOK COMPARE-FUN KEYMAP SHUFFLE-P IDS TAG-TRANSITIONS)")
(register-definition-prefixes "el-secretario-org" '("el-secretario-org-"))

;;; End of scraped data

(provide 'el-secretario-org-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; el-secretario-org-autoloads.el ends here
