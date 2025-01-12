;;; lsp-metals-treeview.el --- LSP Scala Metals Treeview   -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Darren Syzling <dsyzling@gmail.com>, Evgeny Kurnevsky <kurnevsky@gmail.com>

;; Version: 1.0.0
;; Package-Requires: ((emacs "26.1") (lsp-mode "7.0") (dash "2.18.0") (f "0.20.0") (ht "2.0") (treemacs "2.5"))
;; Author: Darren Syzling <dsyzling@gmail.com>
;;         Evgeny Kurnevsky <kurnevsky@gmail.com>
;; Keywords: languages, extensions
;; URL: https://github.com/emacs-lsp/lsp-metals

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

;; lsp-metals treeview ui client - handles a treeview for project tree,
;; compilation tree etc.
;; See the Metals treeview provider spec for further details:
;;  https://scalameta.org/metals/docs/editors/tree-view-protocol.html
;;
;; Current treeview interaction is:
;;   tab  key to expand/collapse nodes which is default treemacs behaviour.
;;   ret  will execute the command associated with the current node via Metals.
;;        Note you need -Dmetals.execute-client-command enabled for this to work
;;        and may require you to upgrade Metals post 0.7 for Emacs.
;;
;;   mouse left double click - will execute the command on a node.
;;
;; Metals allows classes to be expanded and the action executed on the same
;; node - metals.goto (goto definition) we can't therefore use return to
;; expand/collapse and execute actions.  The existing implementation provides
;; a simple starting point to test the treeview with metals and we can evolve
;; to a Hydra like interface to provide a richer keyboard experience in future.
;;

;;; Code:

(require 'ht)
(require 'json)
(require 'dash)
(require 'f)
(require 'seq)
(require 'pcase)
(require 'treemacs)
(require 'lsp-mode)
(require 'lsp-treemacs)
(require 'lsp-metals-protocol)


(defcustom lsp-metals-treeview-logging nil
  "If non nil log treeview trace/debug messages to the 'lsp-log' for debugging."
  :group 'lsp-metals-treeview
  :type 'boolean)

(defcustom lsp-metals-treeview-workspace-switch-delay 0.2
  "Delay in seconds for switching treeview between workspaces.
The delay occurs after 'buffer-list-update-hook' is called before
triggering a switch of treeview when navigating between buffers in
different workspaces."
  :group 'lsp-metals-treeview
  :type 'float)

(defcustom lsp-metals-treeview-views '("metalsPackages"
                                       "metalsBuild"
                                       "metalsCompile"
                                       "metalsHelp")
  "List of views to display."
  :group 'lsp-metals-treeview
  :type '(repeat string)
  :package-version '(lsp-metals . "1.2"))

(defcustom lsp-metals-treeview-theme 'Metals-light
  "The theme for treeview icons."
  :group 'lsp-metals-treeview
  :type '(choice
           (const :tag "Light" 'Metals-light)
           (const :tag "Dark" 'Metals-dark))
  :package-version '(lsp-metals . "1.2"))

(defvar-local lsp-metals-treeview--current-workspace nil
  "Associate lsp workspace with the metals treeview buffer.
Needed to make async calls to the lsp server from treemacs buffers.")

(defvar-local lsp-metals-treeview--view-id nil
  "Metals treeview id associated with the treeview buffer.")

;; Key set on the root of Metals tree - path will be of the form
;; '(:custom MetalsTree) - initialise our root node and we use this
;; to find the root node and refresh the tree.
(defconst lsp-metals-treeview--root-key 'MetalsTree)

(defconst lsp-metals-treeview--icon-dir "icons"
  "Directory containing Metals treeview icon theme.
Directory is relative to lsp-metals.")

(defconst lsp-metals-treeview--buffer-prefix " *Metals"
  "Prefix for all Metals treeview buffers.
Note the space prefix which hides the buffers within the buffer
list in Emacs.")

;; Root directory of our lisp files so that we can find icons
;; relative to installation.
(defconst lsp-metals-treeview--dir
  (-> (if load-file-name
          (file-name-directory load-file-name)
        default-directory)
      (expand-file-name))
  "The directory lsp-metals-treeview.el is stored in.")

(defconst lsp-metals-treeview--buffers-key "metals-treeview-buffers"
  "Metadata key to store treeview buffers within workspace.")

(defconst lsp-metals-treeview--metals-server-id 'metals
  "Server id metals lsp client should be registered from within lsp-metals.")

;;
;; Treemacs doesn't support a unique key - :-key-form isn't actually defined as
;; being unique and you cannot search by this key - only by path. Since Metals
;; sends us nodeUri unique keys we need someway of mapping nodeUris to
;; treemacs paths - so we can use treemacs-find-node.
;;
(defvar-local lsp-metals-treeview--treemacs-node-index (make-hash-table :test 'equal))

(defvar lsp-metals-treeview--active-view-workspace nil
  "Workspace associated with the active treeview instance.
When the treeview is displayed and visible this variable
will hold the workspace.")

(defun lsp-metals-treeview--position (slot)
  "Side window position of Metals treeview with the given SLOT.
Uses defaults for treemacs position and width."
  `((side . ,treemacs-position)
    (slot . ,slot)
    (window-width . ,treemacs-width)))

(defun lsp-metals-treeview--buffer-changed ()
  "Active buffer has changed check if current treeview is valid.
When the buffer is switched check to see if a treeview
is currently being displayed and whether we need to show
an alternative workspace's treeview."
  (with-current-buffer (current-buffer)
    (when (and (eq major-mode 'scala-mode)
               (lsp-find-workspace lsp-metals-treeview--metals-server-id nil)
               lsp-metals-treeview--active-view-workspace
               (not (member lsp-metals-treeview--active-view-workspace
                            (lsp-workspaces))))

      ;; hide current treeview and show new window associated with
      ;; the current workspace of file in buffer.
      (lsp-metals-treeview--hide-window lsp-metals-treeview--active-view-workspace)
      (lsp-metals-treeview--show-window (car (lsp-workspaces))))))

(defun lsp-metals-treeview--buffer-list-update ()
  "Active buffer changed check if treeview needs to be changed.
If the user switches buffers in different workspaces we need to
swap the treeview to show the new workspace's treeview."
  (run-with-idle-timer lsp-metals-treeview-workspace-switch-delay
                       nil
                       #'lsp-metals-treeview--buffer-changed))

(defun lsp-metals-treeview--add-workspace-switch-hook ()
  "Add hook to swap treeviews between workspace buffers.
Add a 'buffer-list-update-hook' to hide/show the active treeview
- if currently displayed - when the user switches buffers that are
within another workspace."
  (add-hook 'buffer-list-update-hook
            #'lsp-metals-treeview--buffer-list-update))

(defun lsp-metals-treeview--remove-workspace-switch-hook ()
  "Remove the hook to swap treeviews between workspace buffers.
Remove the 'buffer-list-update-hook' which deals with switching
treeview when the active buffer switches between different
workspaces."
  (remove-hook 'buffer-list-update-hook
               #'lsp-metals-treeview--buffer-list-update))

(defun lsp-metals-treeview--log (format &rest args)
  "Log treeview tracing/debug messages to the lsp log.
Use the FORMAT formatting string and ARGS arguments to format
the message and parameters."
  (when lsp-metals-treeview-logging
    (apply #'lsp-log format args)))

(defun lsp-metals-treeview--add-buffer (workspace view-id buffer)
  "Add BUFFER with key VIEW-ID to treeview buffers stored in the WORKSPACE."
  (push (cons view-id buffer) (ht-get (lsp--workspace-metadata workspace) lsp-metals-treeview--buffers-key)))

(defun lsp-metals-treeview--remove-buffers (workspace)
  "Clear treeview buffers stored in the WORKSPACE."
  (setf (ht-get (lsp--workspace-metadata workspace) lsp-metals-treeview--buffers-key) nil))

(defun lsp-metals-treeview--get-buffers (workspace)
  "Return buffers stored in the WORKSPACE."
  (-map #'cdr (ht-get (lsp--workspace-metadata workspace) lsp-metals-treeview--buffers-key)))

(defun lsp-metals-treeview--get-buffer-by-id (workspace view-id)
  "Return buffer with key VIEW-ID stored in the WORKSPACE."
  (alist-get view-id (ht-get (lsp--workspace-metadata workspace) lsp-metals-treeview--buffers-key) nil nil #'equal))

(defun lsp-metals-treeview--view-name (view-id)
  "Return a view name from the VIEW-ID."
  (replace-regexp-in-string "metals" "" view-id))

(defun lsp-metals-treeview--buffer-name (workspace view-id)
  "Return buffer name of the treeview from WORKSPACE and VIEW-ID."
  (format "%s %s %s*"
          lsp-metals-treeview--buffer-prefix
          (lsp-metals-treeview--view-name view-id)
          (file-name-nondirectory
           (directory-file-name (lsp--workspace-root workspace)))))

(defun lsp-metals-treeview--hide-window (&optional workspace)
  "Hide the Metals treeview window associated with the WORKSPACE.
The window will be deleted but the treeview buffers will still
be live in the background."
  (interactive)
  (-when-let (cur-workspace (or workspace lsp-metals-treeview--current-workspace))
    (-map (lambda (buffer)
            ;; Notify Metals that visibility of the view has changed
            (with-current-buffer buffer
              (lsp-metals-treeview--send-visibility-did-change
               cur-workspace lsp-metals-treeview--view-id nil))
            (delete-window (get-buffer-window buffer)))
          (lsp-metals-treeview--get-buffers cur-workspace))
    (setq lsp-metals-treeview--active-view-workspace nil)
    ;; Only keep this treeview switching hook live when absolutely necessary
    (lsp-metals-treeview--remove-workspace-switch-hook)))

(defun lsp-metals-treeview--get-visible-buffers ()
  "Retrieve buffers associated with the current selected frame.
Check to see if any of these buffers are metals treeview buffers and
if so return the buffers."
  ;; retrieve any treeview buffers that are visible
  (->> (window-list (selected-frame))
       (-keep (lambda (window)
               (let ((buffer (window-buffer window)))
                 (when (s-starts-with? lsp-metals-treeview--buffer-prefix
                                       (buffer-name buffer))
                   buffer))))))

(defun lsp-metals-treeview--visible? (workspace)
  "Is the metals treeview associated with the WORKSPACE currently visible?"
  (-when-let* ((visible-buffers (lsp-metals-treeview--get-visible-buffers))
               (workspace-buffers (lsp-metals-treeview--get-buffers workspace)))
    (equal visible-buffers workspace-buffers)))

(defun lsp-metals-treeview--exists? (workspace)
  "Does a Metals Treeview exist for the WORKSPACE?
The treeview may not be visible but still exists in the background."
  (-when-let (buffers (lsp-metals-treeview--get-buffers workspace))
    (-all-p 'buffer-live-p buffers)))

(defun lsp-metals-treeview--hidden? (workspace)
  "Does the metals treeview associated with WORKSPACE exist but not visible?"
  (and (lsp-metals-treeview--exists? workspace)
       (not (lsp-metals-treeview--visible? workspace))))

(defun lsp-metals-treeview--get-visibility (workspace)
  "Return visibility status of metals treeview associated with WORKSPACE.
Return 'visible, 'hidden, 'none depending on state of treeview."
  (cond
   ((lsp-metals-treeview--visible? workspace) 'visible)
   ((lsp-metals-treeview--exists? workspace)  'hidden)
   (t 'none)))

(defun lsp-metals-treeview--show-window (workspace &optional select-window?)
  "Show metals treeview window associated with WORKSPACE.
Optionally select the window based on SELECT-WINDOW? being True.
If the treeview window is hidden or not visible (not created)
then show the window."
  (let ((visibility (lsp-metals-treeview--get-visibility workspace)))
    (when (or (eq 'hidden visibility) (eq 'none visibility))
      (lsp-metals-treeview--show-views workspace 0 select-window?))))

(defun lsp-metals-treeview--delete-window (&optional workspace workspace-shutdown?)
  "Delete the metals treeview window associated with the WORKSPACE.
If WORKSPACE is not provided the current treeview buffer local variable
WORKSPACE will be used.  This function is also called from an lsp hook
which will be called when the workspace is shutdown - in this case we
won't notify Metals of view being hidden if WORKSPACE-SHUTDOWN? is
t."
  (let ((cur-workspace (or workspace lsp-metals-treeview--current-workspace)))
    (-map (lambda (treeview-buffer)
            (switch-to-buffer treeview-buffer)
            ;; Tell metals the view is no longer visible but only if
            ;; the workspace isn't in the process of shutting down or
            ;; not initialised.
            (when (and lsp-metals-treeview--view-id
                       (not workspace-shutdown?)
                       (equal 'initialized (lsp--workspace-status cur-workspace)))
              (lsp-metals-treeview--send-visibility-did-change
               lsp-metals-treeview--current-workspace
               lsp-metals-treeview--view-id
               nil))
            (kill-buffer treeview-buffer))
          (lsp-metals-treeview--get-buffers cur-workspace))
    (lsp-metals-treeview--remove-buffers cur-workspace)
    (setq lsp-metals-treeview--active-view-workspace nil)
    ;; Only keep this treeview switching hook live when absolutely necessary.
    (lsp-metals-treeview--remove-workspace-switch-hook)
    (remove-hook 'lsp-after-uninitialized-hook #'lsp-metals-treeview--delete-window)))

(defun lsp-metals-treeview--on-workspace-shutdown (workspace)
  "Handler for lsp WORKSPACE shutdown.
Ensure we close our treeview windows/buffers.  Under this scenario we
shouldn't contact Metals to update view visibility status, so we pass
through workspace-shutdown true so that the 'delete-window' function has
the context of the window closing."
  (lsp-metals-treeview--delete-window workspace t))

;;
;; Minor mode for metals treeview window and keymap to control
;; functions such as closing window.
;;

(defvar lsp-metals-treeview-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "q") #'lsp-metals-treeview--hide-window)
    m)
  "Keymap for 'lsp-metals-treeview-mode'.")

(define-minor-mode lsp-metals-treeview-mode
  "LSP Metals Treeview minor mode."
  :keymap lsp-metals-treeview-mode-map
  :group 'lsp-metals-treeview)


(defun lsp-metals-treeview--show-view (workspace view-id position)
  "Show or create the side window and treeview.
The window will be created for the Metals VIEW-ID within the current WORKSPACE.
The window will be positioned as a side window by POSITION and is of the
form '((side left))."
  (let ((buffer-name (lsp-metals-treeview--buffer-name workspace
                                                       (lsp-metals-treeview--view-name view-id))))
    ;; When opening or refreshing the view do temporarily switch focus but restore
    ;; after window has been created. User will then not be diverted away from their
    ;; current focus..
    (-if-let (buffer (get-buffer buffer-name))
        (with-selected-window (display-buffer-in-side-window buffer position)
          ;; update the root of the tree with the view.
          (lsp-metals-treeview--log "Refreshing tree %s" view-id)
          (treemacs-update-node `(:custom ,lsp-metals-treeview--root-key) t)
          (set-window-dedicated-p (selected-window) t)
          ;; When closing other windows after splitting, prevent our treeview closing.
          (set-window-parameter (selected-window) 'no-delete-other-windows t))

      (let* ((buffer (get-buffer-create buffer-name))
             (window (display-buffer-in-side-window buffer position)))

        (with-lsp-workspace workspace
          (with-selected-window window
            (set-window-dedicated-p window t)
            (treemacs-initialize)

            (setq-local lsp-metals-treeview--current-workspace workspace)
            (setq-local lsp-metals-treeview--view-id view-id)
            (treemacs-METALS-ROOT-extension)
            (setq-local mode-line-format (lsp-metals-treeview--view-name view-id))

            ;; Add buffer to list of treeview buffers associated with this workspace.
            (lsp-metals-treeview--add-buffer workspace view-id buffer)

            ;; When closing other windows after splitting, prevent our treeview closing.
            (set-window-parameter window 'no-delete-other-windows t)
            (lsp-metals-treeview-mode 1)

            ;; Support for link-hint package with default visit action.
            (setq-local treemacs-default-visit-action 'treemacs-RET-action)

            ;; open root of tree after initialisation.
            (treemacs-expand-metals-root)))))))


(defun lsp-metals-treeview--display-views (workspace views slot)
  "Recursive function to display each view in VIEWS.
The views will be associated with the WORKSPACE and displayed in the side
window based based on an increasing SLOT number position."
  (when-let ((view-id (car views)))
    (lsp-metals-treeview--show-view workspace
                           view-id
                           (lsp-metals-treeview--position slot))
    (lsp-metals-treeview--send-visibility-did-change workspace view-id t)
    (lsp-metals-treeview--display-views workspace (cdr views) (+ 1 slot))))

(defun lsp-metals-treeview--select-window (workspace)
  "Switch focus to the treeview window in the given WORKSPACE.
Select the first view/buffer in the treeview window."
  (select-window (get-buffer-window
                  (car (lsp-metals-treeview--get-buffers workspace)))))

(defun lsp-metals-treeview--show-views (workspace slot &optional select-treeview-window)
  "Display each metals view in our sidebar treeview window.
Views are displayed for this WORKSPACE.  SLOT is a numeric position starting
from 0 where the treeview will be positioned relative to the others.  when
SELECT-TREEVIEW-WINDOW is 't' the treeview window will be selected and have
focus."
  (lsp-metals-treeview--display-views workspace lsp-metals-treeview-views slot)

  (when select-treeview-window
    (lsp-metals-treeview--select-window workspace))

  (setq lsp-metals-treeview--active-view-workspace workspace)

  ;; When user switches between files in workspaces automatically switch
  ;; the treeview to the appropriate one.
  (lsp-metals-treeview--add-workspace-switch-hook)

  ;; Add hook to close our treeview when the workspace is shutdown.
  (add-hook 'lsp-after-uninitialized-hook #'lsp-metals-treeview--on-workspace-shutdown))


(defun lsp-metals-treeview--cache-add-nodes (metals-nodes current-treemacs-node)
  "Build an index of treemacs nodes nodeUri -> treemacs path.
We can use this to find nodes within the tree based on nodeUri which
Metals will send us.  METALS-NODES contains a list of new nodes added to
the tree to be displayed, CURRENT-TREEMACS-NODE is the paren to the new
nodes."
  (let ((parent-path (treemacs-button-get current-treemacs-node :path)))
    (-map (lambda (metals-node)
            (-when-let ((&TreeViewNode :node-uri?) metals-node)
              (ht-set lsp-metals-treeview--treemacs-node-index
                      node-uri?
                      (append parent-path (list node-uri?)))))
          metals-nodes)))

(defun lsp-metals-treeview--find-node (node-uri)
  "Find treemacs node based on NODE-URI via our local index.
If the node cannot be found in the tree make sure we cleanup the cache
and remove it."
  (-if-let* ((path (ht-get lsp-metals-treeview--treemacs-node-index node-uri))
             (found-node (treemacs-find-node path)))
      found-node
    ;; Otherwise remove node form cache it's no longer in the tree.
    (ht-remove lsp-metals-treeview--treemacs-node-index node-uri)
    nil))


(lsp-defun lsp-metals-treeview--did-change (workspace (&TreeViewDidChangeParams :nodes))
  "Metals treeview changed notification.
Nodes that have been changed will be provided within the
PARAMS message with their viewIds.  WORKSPACE will be the current
workspace of the project."
  (lsp-metals-treeview--log "In lsp-metals-treeview--did-change %s\n%s"
                            (lsp--workspace-root workspace)
                            (lsp--json-serialize nodes))

  (mapc (lambda (node)
          (-when-let* (((&TreeViewNode :view-id :label) node)
                       (buffer (lsp-metals-treeview--get-buffer-by-id workspace view-id)))
            (with-current-buffer buffer
              (-if-let ((&TreeViewNode :node-uri?) node)
                  (-if-let (tree-node (lsp-metals-treeview--find-node node-uri?))
                      (progn
                        ;; replace label in our node attached to the tree node.
                        (lsp:set-tree-view-node-label (treemacs-button-get tree-node :node) label)

                        ;; Currently the only way to re-render the label of an item is
                        ;; for the parent to call render-node on its children. So
                        ;; we update the parent of the node we're changing.
                        ;; An enhancement to treemacs is in the works where  the label
                        ;; can be updated directly.
                        (treemacs-update-node (treemacs-button-get tree-node :parent) nil))
                    (lsp-metals-treeview--log "Failed to find node in treeview"))
                (treemacs-update-node `(:custom ,lsp-metals-treeview--root-key) t)))))
        nodes))


(defun lsp-metals-treeview--send-treeview-children (view-id &optional node-uri)
  "Query children in the view given by VIEW-ID.
An optional NODE-URI can be used to query children of a specific node
within the view.  This call is synchronous and will return the response
from the call to metas/treeViewChildren.  Under the hood LSP-REQUEST will
send the request asynchronously and wait for the response."
  (lsp-metals-treeview--log "Sending metals/treeViewChildren")
  (lsp-request "metals/treeViewChildren"
               (append `(:viewId ,view-id)
                       (if node-uri `(:nodeUri ,node-uri) nil))))


(defun lsp-metals-treeview--send-visibility-did-change (workspace view-id visible?)
  "Send metals/treeViewVisibilityDidChange when views are shown/hidden.
We need to keep Metals informed when views are shown/hidden so it can optimise
the notification messages it sends us.  WORKSPACE is the current lsp workspace,
VIEW-ID is the view for which the visibility has changed described by the
boolean value VISIBLE - t or nil."
  (lsp-metals-treeview--log "view visibility changed %s %s" view-id visible?)
  (let ((params (list :viewId view-id
                      :visible visible?)))
    (with-lsp-workspace workspace
        (lsp-request-async "metals/treeViewVisibilityDidChange" params
                           (lambda (response)
                             (lsp-metals-treeview--log (lsp--json-serialize response)))
                           :mode 'detached))))

(defun lsp-metals-treeview--send-node-collapse-did-change (workspace view-id node-uri collapsed?)
  "Send metals/treeViewNodeCollapseDidChange when a node has collapsed/expanded.
WORKSPACE is the current workspace, VIEW-ID the id of the view containing the
node with NODE-URI which has been collapsed or expanded based on the boolean
COLLAPSED? either t or nil."
  (lsp-metals-treeview--log "sending metals/treeViewNodeCollapseDidChange viewId %s nodeUri %s collapsed? %s"
                            view-id node-uri collapsed?)
  (let ((params (list :viewId view-id
                      :nodeUri node-uri
                      :collapsed (if collapsed?
                                     t
                                   json-false))))
    (with-lsp-workspace workspace
      (lsp-request-async "metals/treeViewNodeCollapseDidChange" params
                         (lambda (response)
                           (lsp-metals-treeview--log "metals/treeViewNodeCollapseDidChange response:\n %s"
                                                     (lsp--json-serialize response)))
                         :mode 'detached))))

(defun lsp-metals-treeview--get-children (view-id &optional node-uri)
  "Retrieve children of the view given by the VIEW-ID and optionally the node.
Children of the view can be returned and optionally by specifying a NODE-URI
this function will return the node's children.  Without a NODE-URI the top
level child items will be returned for the view.  Returns a list of nodes
with values converted from json to hash tables."
  (with-lsp-workspace lsp-metals-treeview--current-workspace
    ;; return nodes element and convert from vector to list.
    (-let* ((current-tree-node (treemacs-node-at-point))
            ((&TreeViewChildrenResult :nodes) (lsp-metals-treeview--send-treeview-children view-id node-uri))
            (children (append nodes nil)))
      (lsp-metals-treeview--log "Children returned:\n%s" (lsp--json-serialize nodes))
      (when (and (-non-nil children) current-tree-node)
        (lsp-metals-treeview--cache-add-nodes children current-tree-node))
      children)))

(defun lsp-metals-treeview--get-children-current-node (&rest _)
  "Retrieve children of the currently selected node in the treeview.
See LSP-METALS-TREEVIEW--GET-CHILDREN."
  (-when-let* ((tree-node (treemacs-node-at-point))
               (metals-node (treemacs-button-get tree-node :node))
               ((&TreeViewNode :view-id :node-uri?) metals-node))
    (lsp-metals-treeview--get-children view-id node-uri?)))

;;
;; UI tree view using treemacs
;;

(defun lsp-metals-treeview--icon (metals-node open-form?)
  "Return icon based on METALS-NODE.
The icon will depend on the individual METALS-NODE and whether the
node is expanding based on OPEN-FORM? being True.  Check if icon matches
one of our icons for the Metals theme and if not display a standard +/-
if this is an expandable node.  If the node isn't expandable for now
do not show an icon."
  (-if-let ((&TreeViewNode :icon?) metals-node)
      (or (treemacs-get-icon-value icon? nil 'Metals)
          (treemacs-get-icon-value icon? nil lsp-metals-treeview-theme))
    (if (lsp-get metals-node :collapseState)
        (treemacs-get-icon-value
         (if open-form? 'expanded 'collapsed)
         nil
         lsp-treemacs-theme)

      ;; leaf node without an icon
      (treemacs-as-icon "   " 'face 'font-lock-string-face))))

(defun lsp-metals-treeview--send-execute-command-async (command &optional args)
  "Create and send a 'workspace/executeCommand'.
The message will contain the COMMAND and optional ARGS.  Send the
command asynchronously rather than the default 'lsp-mode' of synchronous."
  (lsp-request-async "workspace/executeCommand"
                     (list :command command
                           :arguments args)
                     #'ignore
                     :mode 'detached))

(defun lsp-metals-treeview--exec-node-action (&rest _)
  "Execute the action associated with the treeview node."
  (-when-let* ((node (treemacs-button-get (treemacs-current-button) :node))
               ((&TreeViewNode :command?) node)
               ((&TreeViewCommand :command) command?))
    (with-lsp-workspace lsp-metals-treeview--current-workspace
      (pcase command
        ;; TODO: use `seq-first' after switching to emacs 27.
        (`"metals-echo-command" (lsp-metals-treeview--send-execute-command-async (seq-elt (lsp-get command? :arguments) 0)))
        (c (lsp-metals-treeview--send-execute-command-async c (lsp-get command? :arguments)))))))

(lsp-defun lsp-metals-treeview--on-node-collapsed ((&TreeViewNode :node-uri?) collapsed?)
  "Send metals/treeViewNodeCollapseDidChange to indicate collapsed/expanded.
Metals node is a node attached to treemacs in the :node key - passed as item
during render.  COLLAPSED? either t or nil dependong on if the node has been
collapsed or expanded."
  (lsp-metals-treeview--send-node-collapse-did-change lsp-metals-treeview--current-workspace
                                                      lsp-metals-treeview--view-id
                                                      node-uri?
                                                      collapsed?))

;;
;; Icon theme for Metals treeview
;; Icons taken from vs code Metals code - although Metals draws letters on
;; the icons to indicate Class (C), method(M) etc. Would be nice to redesign
;; these in the future.
;;   https://github.com/scalameta/metals-vscode/tree/master/icons
;;
(treemacs-create-theme "Metals"
  :icon-directory (f-join lsp-metals-treeview--dir lsp-metals-treeview--icon-dir)
  :config
  (progn
    ;; root icon
    (treemacs-create-icon :file "logo.png"        :extensions (root)       :fallback "")

    ;; symbol icons
    (treemacs-create-icon :file "method.png"      :extensions ("method"))
    (treemacs-create-icon :file "class.png"       :extensions ("class"))
    (treemacs-create-icon :file "object.png"      :extensions ("object"))
    (treemacs-create-icon :file "enum.png"        :extensions ("enum"))
    (treemacs-create-icon :file "field.png"       :extensions ("field"))
    (treemacs-create-icon :file "interface.png"   :extensions ("interface"))
    (treemacs-create-icon :file "trait.png"       :extensions ("trait"))
    (treemacs-create-icon :file "val.png"         :extensions ("val"))
    (treemacs-create-icon :file "var.png"         :extensions ("var"))))

(treemacs-create-theme "Metals-dark"
  :icon-directory (f-join lsp-metals-treeview--dir lsp-metals-treeview--icon-dir)
  :config
  (progn
    (treemacs-create-icon :file "book-dark.png" :extensions ("book"))
    (treemacs-create-icon :file "bug-dark.png" :extensions ("bug"))
    (treemacs-create-icon :file "github-dark.png" :extensions ("github"))
    (treemacs-create-icon :file "gitter-dark.png" :extensions ("gitter"))
    (treemacs-create-icon :file "issue-opened-dark.png" :extensions ("issue-opened"))
    (treemacs-create-icon :file "twitter-dark.png" :extensions ("twitter"))
    (treemacs-create-icon :file "discord-dark.png" :extensions ("discord"))))

(treemacs-create-theme "Metals-light"
  :icon-directory (f-join lsp-metals-treeview--dir lsp-metals-treeview--icon-dir)
  :config
  (progn
    (treemacs-create-icon :file "book-light.png" :extensions ("book"))
    (treemacs-create-icon :file "bug-light.png" :extensions ("bug"))
    (treemacs-create-icon :file "github-light.png" :extensions ("github"))
    (treemacs-create-icon :file "gitter-light.png" :extensions ("gitter"))
    (treemacs-create-icon :file "issue-opened-light.png" :extensions ("issue-opened"))
    (treemacs-create-icon :file "twitter-light.png" :extensions ("twitter"))
    (treemacs-create-icon :file "discord-light.png" :extensions ("discord"))))

;;
;; We can possibly remove the leaf node definition and
;; replace lsp-metals-treeview--state to return treemacs-metals-node-closed-state
;;
(treemacs-define-leaf-node metals-leaf 'dynamic-icon

  :ret-action #'lsp-metals-treeview--exec-node-action
  :mouse1-action (lambda (&rest args)
                   (interactive)
                   (lsp-metals-treeview--exec-node-action args)))

;;
;; Expandable node definition in the treemacs tree.
;; Can have an action associated with it - e.g. a class
;; with goto definition, or be a class that can be expanded
;; to show fields, functions etc.
;; Tab expands expandable nodes, return executes the action
;; on the node - although we will change this in future with
;; a keymap or hydra interface to allow more actions.
;;

(treemacs-define-expandable-node metals-node
  :icon-open-form (lsp-metals-treeview--icon
                   (treemacs-button-get (treemacs-node-at-point) :node) t)
  :icon-closed-form (lsp-metals-treeview--icon
                     (treemacs-button-get (treemacs-node-at-point) :node) nil)

  :query-function (lsp-metals-treeview--get-children-current-node)

  :ret-action 'lsp-metals-treeview--exec-node-action

  :after-expand (lsp-metals-treeview--on-node-collapsed
                 (treemacs-button-get node :node) nil)
  :after-collapse (lsp-metals-treeview--on-node-collapsed
                   (treemacs-button-get node :node) t)

  :render-action
  (treemacs-render-node
   :icon (lsp-metals-treeview--icon item nil)
   :label-form (lsp-get item :label)
   :state treemacs-metals-node-closed-state
   ;;:state (lsp-metals-treeview--state item)
   :face 'font-lock-string-face
   :key-form (lsp-get item :nodeUri)
   :more-properties (:node item :eldoc (lsp-get item :tooltip))))

;;
;; Root node of Metals treeview, in the first release this is either the
;; Build or Compile tree.
;; Currently disable return action for the root node. Tab expands root nodes
;; and expandable nodes.
;;

(treemacs-define-expandable-node metals-root
  :icon-open (treemacs-get-icon-value 'root nil "Metals")
  :icon-closed (treemacs-get-icon-value 'root nil "Metals")
  :query-function (lsp-metals-treeview--get-children lsp-metals-treeview--view-id)

  :render-action
  (treemacs-render-node
   :icon (lsp-metals-treeview--icon item nil)
   :label-form (lsp-get item :label)
   :state (lsp-metals-treeview--state item)
   :face 'font-lock-keyword-face
   :key-form (lsp-get item :nodeUri)
   :more-properties (:node item :eldoc (lsp-get item :tooltip)))
  :top-level-marker t
  :root-label (lsp-metals-treeview--view-name lsp-metals-treeview--view-id)
  :root-face 'font-lock-type-face
  :root-key-form lsp-metals-treeview--root-key)


(lsp-defun lsp-metals-treeview--state ((&TreeViewNode :collapse-state?))
  "Return the state of the treeview node."
  (if collapse-state?
      treemacs-metals-node-closed-state
    treemacs-metals-leaf-state))

(defun lsp-metals-treeview (&optional workspace)
  "Display the Metals treeview window for the WORKSPACE (optional).
If WORKSPACE is not specified obtain the current workspace for the file in
the current buffer."
  (interactive)
  (-if-let* ((workspace
              (or workspace
                  (lsp-find-workspace lsp-metals-treeview--metals-server-id
                                      (buffer-file-name)))))
      (lsp-metals-treeview--show-window workspace t)
    (message "Current buffer is not within Metals workspace")))

(defun lsp-metals-treeview-reveal ()
  "Find the current buffer file in the treeview."
  (interactive)
  (-let (((&TreeViewRevealResult :view-id :uri-chain) (lsp-request "metals/treeViewReveal" (lsp--text-document-position-params))))
    (-when-let* ((workspace (lsp-find-workspace lsp-metals-treeview--metals-server-id (buffer-file-name)))
                 (treeview-buffer-name (lsp-metals-treeview--buffer-name workspace view-id)))
      (with-current-buffer treeview-buffer-name
        (mapc (lambda (uri)
                (-when-let (tree-node (lsp-metals-treeview--find-node uri))
                  (goto-char (marker-position tree-node))
                  (treemacs-update-node (treemacs-button-get tree-node :path) t)))
              (reverse uri-chain))
        (-when-let (buffer-window (get-buffer-window))
          (set-window-point buffer-window (point))
          (select-window buffer-window))))))


;; Debug helpers to track down issues with treemacs and aid development.
(defun lsp-metals-treeview--debug-node ()
  "Debug helper function to display treemacs node information."
  (interactive)
  (-let [node (treemacs-node-at-point)]
    (message
     "Label: %s
Depth: %s
Key: %s
Path: %s
State: %s
Parent: %s
eldoc: %s
Metals Item: %s"
     (treemacs--get-label-of node)
     (treemacs-button-get node :depth)
     (treemacs-button-get node :key)
     (treemacs-button-get node :path)
     (treemacs-button-get node :state)
     (-some-> node (treemacs-button-get :parent) (treemacs--get-label-of))
     (treemacs-button-get node :eldoc)
     (-some-> node (treemacs-button-get :node)))))


(provide 'lsp-metals-treeview)
;;; lsp-metals-treeview.el ends here

;; Local Variables:
;; End:
