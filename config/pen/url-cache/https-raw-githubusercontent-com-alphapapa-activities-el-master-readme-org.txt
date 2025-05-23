HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 6810
Cache-Control: max-age=300
Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; sandbox
Content-Type: text/plain; charset=utf-8
ETag: W/"732964426cb54d63c46bb75528a16247443cd5ae626515471f37df308c877761"
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-Frame-Options: deny
X-XSS-Protection: 1; mode=block
X-GitHub-Request-Id: 820E:30ED1:4D4B67:5B324C:660BAB74
Accept-Ranges: bytes
Date: Tue, 02 Apr 2024 06:54:03 GMT
Via: 1.1 varnish
X-Served-By: cache-akl10329-AKL
X-Cache: HIT
X-Cache-Hits: 1
X-Timer: S1712040843.425276,VS0,VE1
Vary: Authorization,Accept-Encoding,Origin
Access-Control-Allow-Origin: *
Cross-Origin-Resource-Policy: cross-origin
X-Fastly-Request-ID: 1edeeade455b6e414fba4e067324143a9473d93d
Expires: Tue, 02 Apr 2024 06:59:03 GMT
Source-Age: 22

#+TITLE: activities.el

# NOTE: It would be preferable to put these at the bottom of the file under the export options heading, but it seems that "TEXINFO_DIR_CATEGORY" only works at the top of the file.
#+EXPORT_FILE_NAME: activities.texi
#+TEXINFO_DIR_CATEGORY: Emacs
#+TEXINFO_DIR_TITLE: Activities: (activities)
#+TEXINFO_DIR_DESC: Suspend/resume activities (sets of windows, frames, and buffers)

# ELPA badge image.
[[https://elpa.gnu.org/packages/activities.html][file:https://elpa.gnu.org/packages/activities.svg]]

Inspired by Genera's and KDE's concepts of "activities", this Emacs library allows the user to manage frames/tabs, windows, and buffers according to their purpose.  An "activity" comprises a frame or tab, its window configuration, and the buffers displayed in them--its "state"; this state would be related to a certain task the user performs at various times, such as developing a certain software project, reading and writing email, working with one's Org mode system, etc.

"Suspending" an activity saves the activity's state and closes its frame/tab; the user would do this when finished with the activity's task for the time being.  "Resuming" the activity restores its buffers and windows to its frame/tab; the user would do this when ready to resume the task at a later time.  This saves the user from having to manually arrange the same windows and buffers each time the task is to be done.

Each activity saves two states: the default state, set when the activity is defined by the user, and the last-used state, which was how the user left it when the activity was suspended (or when Emacs exited, etc).  This allows the user to resume the activity where the task was left off, while also allowing it to be reverted to the default state, providing a consistent entry point into the activity.

Internally, the Emacs ~bookmark~ library is used to save and restore buffers' states--that is, any major mode that supports the bookmark system is compatible.  A buffer whose major mode does not support the bookmark system (or does not support it well enough to restore useful state) is not compatible and can't be fully restored, or perhaps not at all; but solving that is as simple as implementing bookmark support for the mode, which is often trivial.

Various hooks are (or will be--feedback is welcome) provided, both globally and per-activity, so that the user can define functions to be called when an activity is saved, restored, or switched from/to.  For example, this could be used to limit the set of buffers offered for switching to within an activity, or to track the time spent in an activity.

* Contents                                                         :noexport:
:PROPERTIES:
:TOC:      :include siblings :depth 0 :force (nothing) :ignore (this) :local (nothing)
:END:
:CONTENTS:
- [[#installation][Installation]]
- [[#configuration][Configuration]]
- [[#usage][Usage]]
- [[#faq][FAQ]]
- [[#changelog][Changelog]]
- [[#development][Development]]
:END:

* Installation

** GNU ELPA

~activities~ may be installed into Emacs versions 29.1 or later from [[https://elpa.gnu.org/packages/activities.html][GNU ELPA]] by using the command ~M-x package-install RET activities RET~.  This will install the latest stable release, which is recommended.

** Quelpa

To install directly from git (e.g. to test a pre-release version), it's recommended to use [[https://framagit.org/steckerhalter/quelpa][Quelpa]]:

1. Install [[https://framagit.org/steckerhalter/quelpa-use-package#installation][quelpa-use-package]] (which can be installed directly from MELPA).
2. Add this form to your init file (see [[Configuration][Configuration]] for more details):

#+BEGIN_SRC elisp
  (use-package activities
    :quelpa (activities :fetcher github :repo "alphapapa/activities.el"))
#+END_SRC

If you choose to install it otherwise, please note that the author can't offer help with manual installation problems.

* Configuration

This is the recommended configuration, in terms of a ~use-package~ form to be placed in the user's init file:

#+BEGIN_SRC elisp
  (use-package activities
    :init
    (activities-mode)
    (activities-tabs-mode)
    ;; Prevent `edebug' default bindings from interfering.
    (setq edebug-inhibit-emacs-lisp-mode-bindings t)

    :bind
    (("C-x C-a C-n" . activities-new)
     ("C-x C-a C-d" . activities-define)
     ("C-x C-a C-a" . activities-resume)
     ("C-x C-a C-s" . activities-suspend)
     ("C-x C-a C-k" . activities-kill)
     ("C-x C-a RET" . activities-switch)
     ("C-x C-a b" . activities-switch-buffer)
     ("C-x C-a g" . activities-revert)
     ("C-x C-a l" . activities-list)))
#+END_SRC

* Usage

** Activities

For the purposes of this library, an "activity" is a window configuration and its associated buffers.  When an activity is "resumed," its buffers are recreated and loaded into the window configuration, which is loaded into a frame or tab.

From the user's perspective, an "activity" should be thought of as something like, "reading my email," "working on my Emacs library," "writing my book," "working for this client," etc.  The user arranges a set of windows and buffers according to what's needed, then saves it as a new activity.  Later, when the user wants to return to doing that activity, the activity is "resumed," which restores the activity's last-seen state, allowing the user to pick up where the activity was left off; but the user may also revert the activity to its default state, which may be used as a kind of entry point to doing the activity in general.

** Compatibility

This library is designed to not interfere with other workflows and tools; it is intended to coexist and allow integration with them.  For example, when ~activities-tabs-mode~ is enabled, non-activity-related tabs are not affected by it; and the user may close any tab using existing tab commands, regardless of whether it is associated with an activity.

** Modes

+ ~activities-mode~ :: Automatically saves activities' states when Emacs is idle and when Emacs exits.  Should be enabled while using this package (otherwise you would have to manually call ~activities-save-all~, which would defeat much of the purpose of this library).
+ ~activities-tabs-mode~ :: Causes activities to be managed as ~tab-bar~ tabs rather than frames (the default).  (/This is what the author uses; bugs present when this mode is not enabled are less likely to be found, so please report them./)

** Workflow

An example of a workflow using activities:

1. Arrange windows in a tab according to an activity you're performing.
2. Call ~activities-define~ (~C-x C-a C-d~) to save the activity under a name.
3. Perform the activity for a while.
4. Change window configuration, change tab, close the tab, or even restart Emacs.
5. Call ~activities-resume~ (~C-x C-a C-a~) to resume the activity where you left off.
6. Return to the original activity state with ~activities-revert~ (~C-x C-a g~).
7. Rearrange windows and buffers.
8. Call ~activities-define~ with a universal prefix argument (~C-u C-x C-a C-d~) to redefine an activity's default state.
9. Suspend the activity with ~activities-suspend~ (~C-x C-a s~) (which saves its last state and closes its frame/tab).

** Bindings

Key bindings are, as always, ultimately up to the user.  However, in [[Configuration][Configuration]], we suggest a set of bindings with a simple philosophy behind them:

+ A binding ending in a ~C~-prefixed key is expected to result in the set of active activities being changed (e.g. defining a new activity, switching to one, or suspending one).
+ A binding not ending in a ~C~-prefixed key is expected to modify an activity (e.g. reverting it) or do something else (like listing activities.)

** Commands

/With the recommended bindings:/

+ ~activities-list~ (~C-x C-a l~) :: List activities in a ~vtable~ buffer in which they can be managed with various commands.
+ ~activities-new~ (~C-x C-a C-n~) :: Switch to a new, empty activity (i.e. one showing a new frame/tab).
+ ~activities-define~ (~C-x C-a C-d~) :: Define a new activity whose default state is the current frame's or tab's window configuration.  With prefix argument, redefine an existing activity (thereby updating its default state to the current state).
+ ~activities-suspend~ (~C-x C-a C-s~) :: Save an activity's state and close its frame or tab.
+ ~activities-kill~ (~C-x C-a C-k~) :: Discard an activity's last state (so when it is resumed, its default state will be used), and close its frame or tab.
+ ~activities-resume~ (~C-x C-a C-a~) :: Resume an activity, switching to a new frame or tab for its window configuration, and restoring its buffers.  With prefix argument, restore its default state rather than its last.
+ ~activities-revert~ (~C-x C-a g~) :: Revert an activity to its default state.
+ ~activities-switch~ (~C-x C-a RET~) :: Switch to an already-active activity.
+ ~activities-switch-buffer~ (~C-x C-a b~) :: Switch to a buffer associated with the current activity (or, with prefix argument, another activity).
+ ~activities-rename~ :: Rename an activity.
+ ~activities-discard~ :: Discard an activity permanently.
+ ~activities-save-all~ :: Save all active activities' states.  (~activities-mode~ does this automatically, so this command should rarely be needed.)

** Bookmarks

When option ~activities-bookmark-store~ is enabled, an Emacs bookmark is stored when a new activity is made.  This allows the command ~bookmark-jump~ (~C-x r b~) to be used to resume an activity (helping to universalize the bookmark system).

* FAQ

+ How is this different from [[https://github.com/alphapapa/burly.el][Burly.el]] or [[https://github.com/alphapapa/bufler.el/][Bufler.el]]? :: Burly is a well-polished tool for restoring window and frame configurations, which could be considered an incubator for some of the ideas furthered here.  Bufler's ~bufler-workspace~ library uses Burly to provide some similar functionality, which is at an exploratory stage.  ~activities~ hopes to provide a longer-term solution more suitable for integration into Emacs.

+ How does this differ from "workspace" packages? :: Yes, there are many Emacs packages that provide "workspace"-like features in one way or another.  To date, only Burly and Bufler seem to offer the ability to restore one across Emacs sessions, including non-file-backed buffers.  As mentioned, ~activities~ is intended to be more refined and easier to use (e.g. automatically saving activities' states when ~activities-mode~ is enabled).  Comparisons to other packages are left to the reader; suffice to say that ~activities~ is intended to provide what other tools haven't, in an idiomatic, intuitive way.  (Feedback is welcome.)

+ How does this differ from the built-in ~desktop-mode~? :: As best this author can tell, ~desktop-mode~ saves and restores one set of buffers, with various options to control its behavior.  It does not use ~bookmark~ internally, which prevents it from restoring non-file-backed buffers.  As well, it is not intended to be used on-demand to switch between sets of buffers, windows, or frames (i.e. "activities").

+ "Activities" haven't seemed to pan out for KDE.  Why would they in Emacs? :: KDE Plasma's Activities system requires applications that can save and restore their state through Plasma, which only (or mostly only?) KDE apps can do, limiting the usefulness of the system.  However, Emacs offers a coherent environment, similar to Lisp machines of yore, and its ~bookmark~ library offers a way for any buffer's major mode to save and restore state, if implemented (which many already are).

+ Why did a buffer not restore correctly? :: Most likely because that buffer's major mode does not support Emacs bookmarks (which ~activities~ uses internally to save and restore buffer state).  But many, if not most, major modes do; and for those that don't, implementing such support is usually trivial (and thereby benefits Emacs as a whole, not just ~activities~).  So contact the major mode's maintainer and ask that ~bookmark~ support be implemented.

+ Why did I get an error? :: Because ~activities~ is at an early stage of development and some of these features are not simple to implement.  But it's based on Burly, which has already been through much bug-fixing, so it should proceed smoothly.  Please report any bugs you find.

* Changelog

** v0.8-pre

Nothing new yet.

** v0.7

*Additions*
+ Command ~activities-new~ switches to a new, "empty" activity.  (See [[https://github.com/alphapapa/activities.el/issues/46][#46]].)

*Changes*
+ Command ~activities-new~ renamed to ~activities-define~, with new binding ~C-x C-a C-d~.  (See [[https://github.com/alphapapa/activities.el/issues/46][#46]].)
+ Improve error message when jumping to a buffer's bookmark signals an error.

*Fixes*
+ Suspending/killing an activity when only one frame/tab is open.
+ Generation of Info manual on GNU ELPA.  (Thanks to Stefan Monnier.)
+ Ignore minimum window sizes and fixed size restrictions.  ([[https://github.com/alphapapa/activity.el/issues/56][#56]].  Thanks to [[https://github.com/jellelicht][Jelle Licht]].)

** v0.6

*Additions*
+ Command ~activities-switch-buffer~ switches to a buffer associated with the current activity (or, with prefix argument, another activity).  (A buffer is considered to be associated with an activity if it has been displayed in its tab.  Note that this feature currently requires ~activities-tabs-mode~.)
+ Command ~activities-rename~ renames an activity.
+ Option ~activities-after-switch-functions~, a hook called after switching to an activity.
+ Option ~activities-set-frame-name~ sets the frame name after switching to an activity.  ([[https://github.com/alphapapa/activities.el/issues/33][#33]].  Thanks to [[https://github.com/jdtsmith][JD Smith]].)
+ Option ~activities-kill-buffers~, when suspending an activity, kills buffers that were only shown in that activity.

*Changes*
+ Default time format in activities list.
+ When saving all activities, don't persist to disk for each activity.  ([[https://github.com/alphapapa/activities.el/issues/34][#34]].  Thanks to [[https://github.com/yrns][Al M.]] for reporting.)

** v0.5.1

*Fixes*
+ Listing activities without last-saved states.

** v0.5

*Additions*
+ Suggest setting variable ~edebug-inhibit-emacs-lisp-mode-bindings~ to avoid conflicts with suggested keybindings.
+ Option ~activities-bookmark-warnings~ enables warning messages when a non-file-visiting buffer can't be bookmarked (for debugging purposes).
+ Option ~activities-resume-into-frame~ controls whether resuming an activity opens a new frame or uses the current one (when ~activities-tabs-mode~ is disabled).  ([[https://github.com/alphapapa/activities.el/issues/22][#22]].  Thanks to [[https://github.com/Icy-Thought][Icy-Thought]] for suggesting.)

*Changes*
+ Command ~activities-kill~ now discards an activity's last state (while ~activities-suspend~ saves its last state), and closes its frame or tab.
+ Face ~activities-tabs-face~ is renamed to ~activities-tabs~, and now inherits from another face by default, which allows it to adjust with the loaded theme.  ([[https://github.com/alphapapa/activities.el/issues/24][#24]].  Thanks to [[https://github.com/karthink][Karthik Chikmagalur]] for suggesting.)

*Fixes*
+ Show a helpful error if a bookmark's target file is missing.  ([[https://github.com/alphapapa/activities.el/issues/17][#17]].  Thanks to [[https://github.com/jdtsmith][JD Smith]] for reporting.)
+ Sort order in ~activities-list~.
+ When discarding an inactive activity, don't switch to it first.  ([[https://github.com/alphapapa/activity.el/issues/18][#18]].  Thanks to [[https://github.com/jdtsmith][JD Smith]] for reporting.)
+ Don't signal an error when ~debug-on-error~ is enabled and a buffer is not visiting a file.  ([[https://github.com/alphapapa/activity.el/issues/25][#25]].  Thanks to [[https://github.com/karthink][Karthik Chikmagalur]] for reporting.)

** v0.4

*Additions*
+ Option ~activities-anti-save-predicates~ prevents saving activity states at inappropriate times.

*Fixes*
+ Don't save activity state if a minibuffer is active.
+ Offer only active activities for suspending.
+ Don't raise frame when saving activity states.  (See [[https://github.com/alphapapa/activities.el/issues/4][#4]].  Thanks to [[https://github.com/jdtsmith][JD Smith]] for reporting.)

** v0.3.3

*Fixes*
+ Command ~activities-list~ shows a helpful message if no activities are defined.  ([[https://github.com/alphapapa/activities.el/issues/11][#11]].  Thanks to [[https://github.com/fuzy112][fuzy112]] for reporting.)
+ Link in documentation (which works locally but not on GNU ELPA at the moment).

** v0.3.2

Updated documentation, etc.

** v0.3.1

*Fixes*
+ Handle case in which ~activities-tabs-mode~ is enabled again without having been disabled (which caused an error in ~tab-bar-mode~). ([[https://github.com/alphapapa/activities.el/issues/7][#7]])

** v0.3

*Additions*
+ Command ~activities-list~ lists activities in a ~vtable~ buffer in which they can be managed.
+ Offer current activity name by default when redefining an activity with ~activities-new~.
+ Record times at which activities' states were updated.

** v0.2

*Additions*
+ Offer current ~project~ name by default for new activities.  (Thanks to [[https://breatheoutbreathe.in][Joseph Turner]].)
+ Use current activity as default for various completions.  (Thanks to [[https://breatheoutbreathe.in][Joseph Turner]].)

*Fixes*
+ Raise frame after selecting it.  (Thanks to [[https://github.com/jdtsmith][JD Smith]] for suggesting.)

** v0.1.3

*Fixes*
+ Autoloads.
+ Command aliases.

** v0.1.2

*Fixes*
+ Some single-window configurations were not restored properly.

** v0.1.1

*Fixes*
+ Silence message about non-file-visiting buffers.

** v0.1

Initial release.

* Development

~activities~ is developed on [[https://github.com/alphapapa/activities.el][GitHub]].  Suggestions, bug reports, and patches are welcome.

** Copyright assignment

This package is part of [[https://www.gnu.org/software/emacs/][GNU Emacs]], being distributed in [[https://elpa.gnu.org/][GNU ELPA]].  Contributions to this project must follow GNU guidelines, which means that, as with other parts of Emacs, patches of more than a few lines must be accompanied by having assigned copyright for the contribution to the FSF.  Contributors who wish to do so may contact [[mailto:emacs-devel@gnu.org][emacs-devel@gnu.org]] to request the assignment form.

* COMMENT Export setup                                             :noexport:
:PROPERTIES:
:TOC:      :ignore this
:END:

# Copied from org-super-agenda's readme, in which much was borrowed from Org's =org-manual.org=.

#+OPTIONS: broken-links:t *:t num:1 toc:1

** Info export options

# NOTE: See note at top of file.

** File-local variables

# NOTE: Setting org-comment-string buffer-locally is a nasty hack to work around GitHub's org-ruby's HTML rendering, which does not respect noexport tags.  The only way to hide this tree from its output is to use the COMMENT keyword, but that prevents Org from processing the export options declared in it.  So since these file-local variables don't affect org-ruby, wet set org-comment-string to an unused keyword, which prevents Org from deleting this tree from the export buffer, which allows it to find the export options in it.  And since org-export does respect the noexport tag, the tree is excluded from the info page.

# Local Variables:
# before-save-hook: org-make-toc
# org-export-initial-scope: buffer
# org-comment-string: "NOTCOMMENT"
# End:
