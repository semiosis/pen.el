;; Known issues:
;; - To select from a menu, while in the terminal
;;   you must drag the mouse across the menu item you want

(tool-bar-mode -1) ; "M-x tool-bar-mode"
(toggle-scroll-bar -1)

(defset menu-bar-file-menu
  (let ((menu (make-sparse-keymap "File")))

    ;; The "File" menu items
    (bindings--define-key menu [exit-emacs]
      '(menu-item "Quit" save-buffers-kill-terminal
                  :help "Save unsaved buffers, then exit"))

    (bindings--define-key menu [separator-exit]
      menu-bar-separator)

    (unless (featurep 'ns)
      (bindings--define-key menu [close-tab]
        '(menu-item "Close Tab" tab-close
                    :visible (fboundp 'tab-close)
                    :help "Close currently selected tab"))
      (bindings--define-key menu [make-tab]
        '(menu-item "New Tab" tab-new
                    :visible (fboundp 'tab-new)
                    :help "Open a new tab"))

      (bindings--define-key menu [separator-tab]
        menu-bar-separator))

    ;; Don't use delete-frame as event name because that is a special
    ;; event.
    (bindings--define-key menu [delete-this-frame]
      '(menu-item "Delete Frame" delete-frame
                  :visible (fboundp 'delete-frame)
                  :enable (delete-frame-enabled-p)
                  :help "Delete currently selected frame"))
    (bindings--define-key menu [make-frame-on-monitor]
      '(menu-item "New Frame on Monitor..." make-frame-on-monitor
                  :visible (fboundp 'make-frame-on-monitor)
                  :help "Open a new frame on another monitor"))
    (bindings--define-key menu [make-frame-on-display]
      '(menu-item "New Frame on Display..." make-frame-on-display
                  :visible (fboundp 'make-frame-on-display)
                  :help "Open a new frame on another display"))
    (bindings--define-key menu [make-frame]
      '(menu-item "New Frame" make-frame-command
                  :visible (fboundp 'make-frame-command)
                  :help "Open a new frame"))

    (bindings--define-key menu [separator-frame]
      menu-bar-separator)

    (bindings--define-key menu [one-window]
      '(menu-item "Remove Other Windows" delete-other-windows
                  :enable (not (one-window-p t nil))
                  :help "Make selected window fill whole frame"))

    (bindings--define-key menu [new-window-on-right]
      '(menu-item "New Window on Right" split-window-right
                  :enable (and (menu-bar-menu-frame-live-and-visible-p)
                               (menu-bar-non-minibuffer-window-p))
                  :help "Make new window on right of selected one"))

    (bindings--define-key menu [new-window-below]
      '(menu-item "New Window Below" split-window-below
                  :enable (and (menu-bar-menu-frame-live-and-visible-p)
                               (menu-bar-non-minibuffer-window-p))
                  :help "Make new window below selected one"))

    (bindings--define-key menu [separator-window]
      menu-bar-separator)

    (bindings--define-key menu [recover-session]
      '(menu-item "Recover Crashed Session" recover-session
                  :enable
                  (and auto-save-list-file-prefix
                       (file-directory-p
                        (file-name-directory auto-save-list-file-prefix))
                       (directory-files
                        (file-name-directory auto-save-list-file-prefix)
                        nil
                        (concat "\\`"
                                (regexp-quote
                                 (file-name-nondirectory
                                  auto-save-list-file-prefix)))
                        t))
                  :help "Recover edits from a crashed session"))
    (bindings--define-key menu [revert-buffer]
      '(menu-item "Revert Buffer" revert-buffer
                  :enable (or (not (eq revert-buffer-function
                                       'revert-buffer--default))
                              (not (eq
                                    revert-buffer-insert-file-contents-function
                                    'revert-buffer-insert-file-contents--default-function))
                              (and buffer-file-number
                                   (or (buffer-modified-p)
                                       (not (verify-visited-file-modtime
                                             (current-buffer))))))
                  :help "Re-read current buffer from its file"))
    (bindings--define-key menu [write-file]
      '(menu-item "Save As..." write-file
                  :enable (and (menu-bar-menu-frame-live-and-visible-p)
                               (menu-bar-non-minibuffer-window-p))
                  :help "Write current buffer to another file"))
    (bindings--define-key menu [save-buffer]
      '(menu-item "Save" save-buffer
                  :enable (and (buffer-modified-p)
                               (buffer-file-name)
                               (menu-bar-non-minibuffer-window-p))
                  :help "Save current buffer to its file"))

    (bindings--define-key menu [separator-save]
      menu-bar-separator)


    (bindings--define-key menu [kill-buffer]
      '(menu-item "Close" kill-this-buffer
                  :enable (kill-this-buffer-enabled-p)
                  :help "Discard (kill) current buffer"))
    (bindings--define-key menu [insert-file]
      '(menu-item "Insert File..." insert-file
                  :enable (menu-bar-non-minibuffer-window-p)
                  :help "Insert another file into current buffer"))
    (bindings--define-key menu [dired]
      '(menu-item "Open Directory..." dired
                  :enable (menu-bar-non-minibuffer-window-p)
                  :help "Read a directory, to operate on its files"))
    (bindings--define-key menu [open-file]
      '(menu-item "Open File..." menu-find-file-existing
                  :enable (menu-bar-non-minibuffer-window-p)
                  :help "Read an existing file into an Emacs buffer"))
    (bindings--define-key menu [new-file]
      '(menu-item "Visit New File..." find-file
                  :enable (menu-bar-non-minibuffer-window-p)
                  :help "Specify a new file's name, to edit the file"))

    menu))

(defset menu-bar-emacs-help-menu
  (let ((menu (make-sparse-keymap "Help")))
    (bindings--define-key menu [about-gnu-project]
      '(menu-item "About GNU" describe-gnu-project
                  :help "About the GNU System, GNU Project, and GNU/Linux"))
    (bindings--define-key menu [about-emacs]
      '(menu-item "About Emacs" about-emacs
                  :help "Display version number, copyright info, and basic help"))
    (bindings--define-key menu [sep4]
      menu-bar-separator)
    (bindings--define-key menu [describe-no-warranty]
      '(menu-item "(Non)Warranty" describe-no-warranty
                  :help "Explain that Emacs has NO WARRANTY"))
    (bindings--define-key menu [describe-copying]
      '(menu-item "Copying Conditions" describe-copying
                  :help "Show the Emacs license (GPL)"))
    (bindings--define-key menu [getting-new-versions]
      '(menu-item "Getting New Versions" describe-distribution
                  :help "How to get the latest version of Emacs"))
    (bindings--define-key menu [sep2]
      menu-bar-separator)
    (bindings--define-key menu [external-packages]
      '(menu-item "Finding Extra Packages" view-external-packages
                  :help "How to get more Lisp packages for use in Emacs"))
    (bindings--define-key menu [find-emacs-packages]
      '(menu-item "Search Built-in Packages" finder-by-keyword
                  :help "Find built-in packages and features by keyword"))
    (bindings--define-key menu [more-manuals]
      `(menu-item "More Manuals" ,menu-bar-manuals-menu))
    (bindings--define-key menu [emacs-manual]
      '(menu-item "Read the Emacs Manual" info-emacs-manual
                  :help "Full documentation of Emacs features"))
    (bindings--define-key menu [describe]
      `(menu-item "Describe" ,menu-bar-describe-menu))
    (bindings--define-key menu [search-documentation]
      `(menu-item "Search Documentation" ,menu-bar-search-documentation-menu))
    (bindings--define-key menu [sep1]
      menu-bar-separator)
    (bindings--define-key menu [emacs-psychotherapist]
      '(menu-item "Emacs Psychotherapist" doctor
                  :help "Our doctor will help you feel better"))
    (bindings--define-key menu [send-emacs-bug-report]
      '(menu-item "Send Bug Report..." report-emacs-bug
                  :help "Send e-mail to Emacs maintainers"))
    (bindings--define-key menu [emacs-manual-bug]
      '(menu-item "How to Report a Bug" info-emacs-bug
                  :help "Read about how to report an Emacs bug"))
    (bindings--define-key menu [emacs-known-problems]
      '(menu-item "Emacs Known Problems" view-emacs-problems
                  :help "Read about known problems with Emacs"))
    (bindings--define-key menu [emacs-news]
      '(menu-item "Emacs News" view-emacs-news
                  :help "New features of this version"))
    (bindings--define-key menu [emacs-faq]
      '(menu-item "Emacs FAQ" view-emacs-FAQ
                  :help "Frequently asked (and answered) questions about Emacs"))

    (bindings--define-key menu [emacs-tutorial-language-specific]
      '(menu-item "Emacs Tutorial (choose language)..."
                  help-with-tutorial-spec-language
                  :help "Learn how to use Emacs (choose a language)"))
    (bindings--define-key menu [emacs-tutorial]
      '(menu-item "Emacs Tutorial" help-with-tutorial
                  :help "Learn how to use Emacs"))

    ;; In macOS it's in the app menu already.
    ;; FIXME? There already is an "About Emacs" (sans ...) entry in the Help menu.
    (and (featurep 'ns)
         (not (eq system-type 'darwin))
         (bindings--define-key menu [info-panel]
           '(menu-item "About Emacs..." ns-do-emacs-info-panel)))
    menu))

(defset menu-bar-daemons-menu
  (let ((menu (make-sparse-keymap "Daemons")))
    (bindings--define-key menu [mi-pen-reload-all]
      '(menu-item "Reload Pen.el config, engines and prompts for all daemons" pen-reload-all
                  :help "Reload Pen.el config, engines and prompts for all daemons"))
    (bindings--define-key menu [mi-pen-watch-daemons]
      '(menu-item "Watch daemons" pen-watch-daemons
                  :help "Watch daemons as their availability changes"))
    (bindings--define-key menu [mi-pen-ka]
      '(menu-item "Kill all daemons" pen-ka
                  :help "Kill all daemon instances"))
    (bindings--define-key menu [mi-pen-fix-daemons]
      '(menu-item "Reset all daemons" pen-fix-daemons
                  :help "Reset all daemon instances"))
    (bindings--define-key menu [mi-pen-qa]
      '(menu-item "Quit all daemons" pen-qa
                  :help "Quit all daemon instances"))
    (bindings--define-key menu [mi-pen-sa]
      '(menu-item "Start all daemons" pen-sa
                  :help "Start all daemon instances"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-keys-menu
  (let ((menu (make-sparse-keymap "Keys")))
    (bindings--define-key menu [mi-pen-add-key-openai]
      '(menu-item "Add OpenAI key" pen-add-key-openai
                  :help "Add, edit or remove the OpenAI key"))
    (bindings--define-key menu [mi-pen-add-key-cohere]
      '(menu-item "Add Cohere key" pen-add-key-cohere
                  :help "Add, edit or remove the Cohere key"))
    (bindings--define-key menu [mi-pen-add-key-goose]
      '(menu-item "Add Goose key" pen-add-key-goose
                  :help "Add, edit or remove the Goose key"))
    (bindings--define-key menu [mi-pen-add-key-hf]
      '(menu-item "Add HuggingFace key" pen-add-key-hf
                  :help "Add, edit or remove the HuggingFace key"))
    (bindings--define-key menu [mi-pen-add-key-alephalpha]
      '(menu-item "Add AlephAlpha key" pen-add-key-alephalpha
                  :help "Add, edit or remove the AlephAlpha key"))
    (bindings--define-key menu [mi-pen-add-key-ai21]
      '(menu-item "Add AI21 key" pen-add-key-ai21
                  :help "Add, edit or remove the AI21 key"))
    (bindings--define-key menu [mi-pen-add-key-hf]
      '(menu-item "Add HuggingFace key" pen-add-key-hf
                  :help "Add, edit or remove the HuggingFace key"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-protocol-menu
  (let ((menu (make-sparse-keymap "࿋  Semiosis Protocol")))
    (bindings--define-key menu [mi-pen-connect-semiosis-protocol]
      '(menu-item "Connect to network" pen-connect-semiosis-protocol
                  :help "Connect Pen.el to the Semiosis Protocol"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-alethea-ai-menu
  (let ((menu (make-sparse-keymap "Alethea.AI")))
    (bindings--define-key menu [mi-pen-connect-alethea-ai]
      '(menu-item "Connect to network" pen-connect-alethea-ai
                  :help "Connect Pen.el to the Alethea.AI"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-network-menu
  (let ((menu (make-sparse-keymap "Networks")))
    (bindings--define-key menu [mi-menu-bar-protocol-menu]
      `(menu-item "࿋  Semiosis Protocol" ,menu-bar-protocol-menu
                  :help "Semiosis Protocol functions"))
    (bindings--define-key menu [mi-menu-bar-alethea-ai-menu]
      `(menu-item "Alethea.AI" ,menu-bar-alethea-ai-menu
                  :help "Alethea.AI functions"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-source-menu
  (let ((menu (make-sparse-keymap "Source")))
    (bindings--define-key menu [mi-pen-acolyte-dired-penel]
      '(menu-item "Go to Pen.el directory" pen-acolyte-dired-penel
                  :help "Go to Pen.el source code"))
    (bindings--define-key menu [mi-pen-acolyte-dired-prompts]
      '(menu-item "Go to prompts" pen-acolyte-dired-prompts
                  :help "Go to prompts source directory"))
    (bindings--define-key menu [mi-pen-acolyte-dired-engines]
      '(menu-item "Go to engines directory" pen-acolyte-dired-engines
                  :help "Go to engines source directory"))
    (bindings--define-key menu [mi-pen-dired-khala]
      '(menu-item "Go to khala directory" pen-dired-khala
                  :help "Go to khala source directory"))
    (bindings--define-key menu [mi-pen-dired-pensieve]
      '(menu-item "Go to pensieve directory" pen-dired-pensieve
                  :help "Go to pensieve source directory"))
    (bindings--define-key menu [mi-pen-dired-rhizome]
      '(menu-item "Go to rhizome directory" pen-dired-rhizome
                  :help "Go to rhizome source directory"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-servers-menu
  (let ((menu (make-sparse-keymap "Servers")))
    (bindings--define-key menu [mi-pen-dired-pensieve]
      '(menu-item "Go to pensieve directory" pen-dired-pensieve
                  :help "Go to pensieve source directory"))
    (bindings--define-key menu [mi-pen-dired-rhizome]
      '(menu-item "Go to rhizome directory" pen-dired-rhizome
                  :help "Go to rhizome source directory"))
    (bindings--define-key menu [mi-pen-dired-khala]
      '(menu-item "Go to khala directory" pen-dired-khala
                  :help "Go to khala source directory"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-configure-menu
  (let ((menu (make-sparse-keymap "Configure")))
    (bindings--define-key menu [mi-pen-go-to-vim-config]
      '(menu-item "Edit vim configuration" pen-go-to-vim-config
                  :help "Edit the vim config"))
    (bindings--define-key menu [mi-pen-edit-conf]
      '(menu-item "Edit Pen.el configuration" pen-edit-conf
                  :help "Edit the pen.yaml file"))
    (bindings--define-key menu [mi-menu-bar-source-menu]
      `(menu-item "Pen.el source code" ,menu-bar-source-menu
                  :help "Manage source code"))
    (bindings--define-key menu [mi-menu-bar-servers-menu]
      `(menu-item "Pen.el servers" ,menu-bar-servers-menu
                  :help "Manage servers"))
    (bindings--define-key menu [mi-pen-edit-efm-conf]
      '(menu-item "Edit ESP configuration" pen-edit-efm-conf
                  :help "Edit the efm-langserver-config.yaml file"))
    (bindings--define-key menu [mi-pen-customize]
      '(menu-item "Customize Pen.el" pen-customize
                  :help "Pen.el customization"))
    (bindings--define-key menu [mi-pen-reload]
      '(menu-item "Reload Pen.el config, engines and prompts" pen-reload
                  :help "Reload Pen.el config, engines and prompts"))
    (bindings--define-key menu [mi-pen-reload-config-file]
      '(menu-item "Reload individual config file" pen-reload-config-file
                  :help "This is useful for editing Pen.el source and reloading"))
    (bindings--define-key menu [mi-menu-bar-keys-menu]
      `(menu-item "Add, remove and edit API keys" ,menu-bar-keys-menu
                  :help "e.g. Add your OpenAI key"))
    (bindings--define-key menu [mi-menu-bar-network-menu]
      `(menu-item "Connect to p2p networks" ,menu-bar-network-menu
                  :help "e.g. Connect Semiosis Protocol"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-documents-menu
  (let ((menu (make-sparse-keymap "Documents")))
    (bindings--define-key menu [mi-pen-go-to-documents]
      '(menu-item "Documents (shared with host)" pen-go-to-documents
                  :help "Open dired at ~/.pen/documents"))
    (bindings--define-key menu [mi-pen-go-to-results]
      '(menu-item "Results (shared with host)" pen-go-to-results
                  :help "Open dired at ~/.pen/results"))
    (bindings--define-key menu [mi-pen-go-to-brains]
      '(menu-item "Brains (shared with host)" pen-go-to-brains
                  :help "Open dired at ~/.pen/org-brain"))
    (bindings--define-key menu [mi-pen-go-to-glossaries]
      '(menu-item "Glossaries (shared with host)" pen-go-to-glossaries
                  :help "Open dired at ~/.pen/glossaries"))
    (bindings--define-key menu [mi-pen-go-to-glossaries]
      '(menu-item "Your Imagination" pen-your-imagination
                  :help "Play the best song ever"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-pen-menu
  (let ((menu (make-sparse-keymap "Pen.el 🖊 ")))
    (bindings--define-key menu [mi-pen-acolyte-dired-penel]
      '(menu-item "Go to Pen.el directory" pen-acolyte-dired-penel
                  :help "Go to Pen.el source code"))
    (bindings--define-key menu [mi-list-processes]
      '(menu-item "List background proceses" list-processes
                  :help "List, and stop running background jobs"))
    (bindings--define-key menu [mi-pen-start-gui-web-browser]
      '(menu-item "Start Pen.el in a GUI web browser" pen-start-gui-web-browser
                  :help "Start Pen.el in a GUI web browser"))
    (bindings--define-key menu [mi-pen-public-web]
      '(menu-item "Start Pen.el with a public web URL" pen-public-web
                  :help "Start Pen.el publicly with its own URL"))
    (bindings--define-key menu [mi-pen-start-gui]
      '(menu-item "Start Pen.el in a GUI" pen-start-gui
                  :help "Start Pen.el in an emacs GUI"))
    (bindings--define-key menu [mi-pen-of-imagination]
      '(menu-item "The pen of imagination - |:ϝ∷¦ϝ" pen-of-imagination
                  :help "The pen of imagination - |:ϝ∷¦ϝ"))
    (bindings--define-key menu [mi-menu-bar-daemons-menu]
      `(menu-item "Daemons" ,menu-bar-daemons-menu
                  :help "Control Pen.el daemons"))
    (bindings--define-key menu [mi-pen-quit]
      '(menu-item "Shutdown Pen.el" pen-kill-emacs
                  :help "Shutdown everything"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-apostrophe-menu
  (let ((menu (make-sparse-keymap "Apostrophe")))
    (bindings--define-key menu [apostrophe-start-chatbot-from-name]
      '(menu-item "Start chatbot from their name" apostrophe-start-chatbot-from-name
                  :help "Speak to someone, given their name"))
    (bindings--define-key menu [mi-apostrophe-start-chatbot-from-selection]
      '(menu-item "Start chatbot from selection" apostrophe-start-chatbot-from-selection
                  :help "Suggest some subject-matter-experts for the selected text, and speak to them"))

    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-cterm-menu
  (let ((menu (make-sparse-keymap "ComplexTerm")))
    (bindings--define-key menu [mi-cterm-start]
      '(menu-item "Start cterm (Pen.el wrapping a host terminal)" cterm-start
                  :help "Pen.el wraps your host's terminal to provide augmented intelligence"))
    (bindings--define-key menu [mi-pet-start]
      '(menu-item "Start pet (Pen.el wrapping a terminal within the docker container)" pet-start
                  :help "Pen.el wraps your host's terminal to provide augmented intelligence"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-channel-menu
  (let ((menu (make-sparse-keymap "Chann.el")))
    (bindings--define-key menu [mi-channel-chatbot-from-name]
      '(menu-item "Channel a chatbot to control your terminal" channel-chatbot-from-name
                  :help "A chatbot takes command of your host terminal"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-ii-lang-menu
  (let ((menu (make-sparse-keymap "Imaginary Interpreter")))
    (bindings--define-key menu [mi-ii-python]
      '(menu-item "𝑖i - Python" ii-python
                  :help "Start a Python imaginary interpreter,"))
    (bindings--define-key menu [mi-ii-bash]
      '(menu-item "𝑖i - Bash" ii-bash
                  :help "Start a Bash imaginary interpreter,"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-ii-menu
  (let ((menu (make-sparse-keymap "Imaginary Interpreter")))
    (bindings--define-key menu [mi-menu-bar-ii-lang-menu]
      `(menu-item "Fully-supported languages" ,menu-bar-ii-lang-menu
                  :help "Start a fully-supported imaginary interpreter"))
    (bindings--define-key menu [mi-ii-language]
      '(menu-item "Start an imaginary interpreter" ii-language
                  :help "Start given the name/language"))
    (bindings--define-key menu [mi-pen-start-ii-from-buffer]
      '(menu-item "Start from the current terminal" pen-start-ii-from-buffer
                  :help "Start an imaginary interpreter from your current terminal"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-real-menu
  (let ((menu (make-sparse-keymap "Real Interpreter")))
    (bindings--define-key menu [mi-prolog]
      '(menu-item "Start a real prolog interpreter" swipl
                  :help "Start SWI Prolog"))
    (bindings--define-key menu [mi-prolog-host]
      '(menu-item "Start a real prolog interpreter on host" swipl-host
                  :help "Start SWI Prolog"))
    (bindings--define-key menu [mi-ipython]
      '(menu-item "Start a real iPython interpreter" ipython
                  :help "Start iPython"))
    (bindings--define-key menu [mi-ipython-host]
      '(menu-item "Start a real iPython interpreter on host" ipython-host
                  :help "Start iPython"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-nlsh-menu
  (let ((menu (make-sparse-keymap "Natural language shell")))
    (bindings--define-key menu [mi-nlsh-os]
      '(menu-item "Start a shell given the OS" nlsh-os
                  :help "Convert natural language into commands"))
    (bindings--define-key menu [mi-sps-nlsh]
      '(menu-item "Start a shell given the OS in tmux" sps-nlsh
                  :help "Convert natural language into commands"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-mtp-menu
  (let ((menu (make-sparse-keymap "MadTeaParty")))
    (bindings--define-key menu [pen-channel-say-something]
      '(menu-item "Say something" channel-say-something
                  :help "While running MTP in pet you can run this to suggest something to say"))
    (bindings--define-key menu [pen-channel-loop-chat]
      '(menu-item "This loops 'Say something'" channel-loop-chat
                  :help "While running MTP in pet you can run this to create a loop which talks continually"))
    (bindings--define-key menu [pen-mtp-connect-with-name]
      '(menu-item "Spawn a new user in Mad Tea-Party" pen-mtp-connect-with-name
                  :help "This starts an irc client for new user to Mad Tea-Party"))
    (bindings--define-key menu [pen-pen-mtp-connect-with-name-using-pet]
      '(menu-item "Spawn a new user in Mad Tea-Party in Pet" pen-mtp-connect-with-name-using-pet
                  :help "This starts an irc client for new user to Mad Tea-Party in Pet"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-continuum-menu
  (let ((menu (make-sparse-keymap "Continuum")))
    (bindings--define-key menu [pen-continuum-push]
      '(menu-item "Push" continuum-push
                  :help "Push a screenshot to Continuum"))
    (bindings--define-key menu [pen-continuum]
      '(menu-item "Forecast" continuum
                  :help "Forecast screen with Continuum"))
    (bindings--define-key menu [pen-continuum-backwards]
      '(menu-item "Backcast" continuum-backwards
                  :help "Backcast screen with Continuum"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-paracosm-menu
  (let ((menu (make-sparse-keymap "Paracosm")))
    (bindings--define-key menu [from-name]
      '(menu-item "Switch brain" pen-org-brain-switch-brain
                  :help "Switch brain"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-esp-menu
  (let ((menu (make-sparse-keymap "ESP")))
    (bindings--define-key menu [mi-lsp]
      '(menu-item "Start LSP (Language Server Protocol)" pen-start-esp
                  :help "Start LSP in current buffer"))
    (bindings--define-key menu [mi-esp]
      '(menu-item "Start ESP (Pen.el LSP server)" pen-start-esp
                  :help "Start ESP (Extra Sensory Perception) in current buffer"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-prompts-menu
  (let ((menu (make-sparse-keymap "Prompts")))
    (bindings--define-key menu [mi-pen-acolyte-dired-prompts]
      '(menu-item "Go to prompts" pen-acolyte-dired-prompts
                  :help "Go to prompts source directory"))
    (bindings--define-key menu [mi-pen-generate-prompt-functions]
      '(menu-item "Generate prompt functions" pen-generate-prompt-functions
                  :help "Regenerate prompt functions"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-engines-menu
  (let ((menu (make-sparse-keymap "Engines")))
    (bindings--define-key menu [mi-pen-acolyte-dired-engines]
      '(menu-item "Go to engines directory" pen-acolyte-dired-engines
                  :help "Go to engines source directory"))
    (bindings--define-key menu [mi-pen-load-engines]
      '(menu-item "Reload engines" pen-load-engines
                  :help "Reload engines from YAML"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-engineering-menu
  (let ((menu (make-sparse-keymap "Engines")))
    (bindings--define-key menu [mi-menu-bar-engines-menu]
      `(menu-item "Engines" ,menu-bar-engines-menu
                  :help "Engines menu"))
    (bindings--define-key menu [mi-menu-bar-prompts-menu]
      `(menu-item "Prompts" ,menu-bar-prompts-menu
                  :help "Prompts menu"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-history-menu
  (let ((menu (make-sparse-keymap "History")))
    (bindings--define-key menu [mi-pen-continue-from-hist]
      '(menu-item "Continue prompt from history" pen-continue-from-hist
                  :help "Continue prompt from history"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-prompting-menu
  (let ((menu (make-sparse-keymap "Prompting")))
    (bindings--define-key menu [mi-pen-run-prompt-function]
      '(menu-item "Run prompt function" pen-run-prompt-function
                  :help "Run a prompt function interactively"))
    (bindings--define-key menu [mi-pen-diagnostics-show-context]
      '(menu-item "Diagnostics" pen-diagnostics-show-context
                  :help "Show details of prompt function execution"))
    (bindings--define-key menu [mi-menu-bar-history-menu]
      `(menu-item "Prompt history" ,menu-bar-history-menu
                  :help "Work with prompt history"))
    (bindings--define-key menu [mi-menu-bar-engineering-menu]
      `(menu-item "Engineering" ,menu-bar-engineering-menu
                  :help "Prompt engineering"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-inkwell-menu
  (let ((menu (make-sparse-keymap "Inkw.el 𑑛")))
    (bindings--define-key menu [mi-pen-go-to-prompt-for-ink]
      '(menu-item "Go to prompt for ink" pen-go-to-prompt-for-ink
                  :help "When the cursor is on some ink, go to the prompt that generated it"))
    (bindings--define-key menu [mi-pen-go-to-engine-for-ink]
      '(menu-item "Go to engine for ink" pen-go-to-engine-for-ink
                  :help "When the cursor is on some ink, go to the engine that generated it"))
    (bindings--define-key menu [mi-ink-get-properties-here]
      '(menu-item "Get ink properties at cursor" ink-get-properties-here
                  :help "When the cursor is on some ink, display the ink source"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-lookingglass-menu
  (let ((menu (make-sparse-keymap "🔍 LookingGlass")))
    (bindings--define-key menu [mi-lg-render]
      '(menu-item "Render" lg-render
                  :help "Render to HTML"))
    (bindings--define-key menu [mi-lg-search]
      '(menu-item "Search" lg-search
                  :help "Search selected passage for URLs"))
    (bindings--define-key menu [mi-lg-eww]
      '(menu-item "Go to URL" lg-eww
                  :help "Go to URL"))
    (bindings--define-key menu [mi-lg-fz-history]
      '(menu-item "URL History" lg-fz-history
                  :help "Look through history of URLs"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-khala-menu
  (let ((menu (make-sparse-keymap "Khala")))
    (bindings--define-key menu [mi-khala-mount-dir]
      '(menu-item "Start Khala" khala-start
                  :help "Start the Khala web server. Only its light was able to bind our people-to give us unity."))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-pensieve-menu
  (let ((menu (make-sparse-keymap "PenSieve")))
    (bindings--define-key menu [mi-pensieve-mount-dir]
      '(menu-item "Mount a new pensieve" pensieve-mount-dir
                  :help "Given the name of the pensieve, mount it on the host and navigate to it"))
    (bindings--define-key menu [mi-pen-go-to-pensieves]
      '(menu-item "Go to pensieves" pen-go-to-pensieves
                  :help "Go to pensieves directory with dired"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-melee-menu
  (let ((menu (make-sparse-keymap "🍓 Melee")))
    (bindings--define-key menu [mi-melee-start-immitation-game]
      '(menu-item "Immitation game" melee-start-immitation-game
                  :help "Start game of immitation"))
    (bindings--define-key menu [mi-melee-start-exquisite-corpse]
      '(menu-item "Exquisite Corpse" melee-start-exquisite-corpse
                  :help "Start game of Exquisite Corpse"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-apps-menu
  (let ((menu (make-sparse-keymap "Applications")))
    (bindings--define-key menu [mi-menu-bar-apostrophe-menu]
      `(menu-item "🎤 Apostrophe" ,menu-bar-apostrophe-menu
                  :help "Talk 1-on-1 to chatbots"))
    (bindings--define-key menu [mi-menu-bar-continuum-menu]
      `(menu-item "∞ Continuum" ,menu-bar-continuum-menu
                  :help "Imagine your computer's state forwards and backwards in time"))
    (bindings--define-key menu [mi-menu-bar-mtp-menu]
      `(menu-item "🎩Mad Tea-Party" ,menu-bar-mtp-menu
                  :help "Partake in simulated group conversation between chatbots and humans"))
    (bindings--define-key menu [mi-menu-bar-real-menu]
      `(menu-item "ℝi Real interpreters" ,menu-bar-real-menu
                  :help "Run imaginary interpreters"))
    (bindings--define-key menu [mi-menu-bar-ii-menu]
      `(menu-item "𝑖i Imaginary interpreters" ,menu-bar-ii-menu
                  :help "Run imaginary interpreters"))
    (bindings--define-key menu [mi-menu-bar-nlsh-menu]
      `(menu-item "🗣️  Natural language shell" ,menu-bar-nlsh-menu
                  :help "Run a natural language shell"))
    (bindings--define-key menu [mi-menu-bar-channel-menu]
      `(menu-item "👻 Chann.el" ,menu-bar-channel-menu
                  :help "Channel personalities to control your computer"))
    (bindings--define-key menu [mi-menu-bar-cterm-menu]
      `(menu-item "💻 ComplexTerm" ,menu-bar-cterm-menu
                  :help "Run your terminals within Pen.el"))
    (bindings--define-key menu [mi-ielm]
      '(menu-item "𝑖λ IELM (elisp with ilambda)" ielm
                  :help "Work with ilambda functions and macros"))
    (bindings--define-key menu [mi-ilambda-repl]
      '(menu-item "𝑖λ quick ilambda REPL" ilambda-repl
                  :help "Run ilambda functions without coding"))
    ;; (bindings--define-key menu [mi-pen-tm-asciinema-play]
    ;;   '(menu-item "Asciinema Play" pen-tm-asciinema-play
    ;;               :help "Play an asciinema recording"))
    (bindings--define-key menu [mi-menu-bar-melee-menu]
      `(menu-item "🍓 Melee" ,menu-bar-melee-menu
                  :help "Mount imaginary filesystems"))
    (bindings--define-key menu [mi-menu-bar-lookingglass-menu]
      `(menu-item "🔍 LookingGlass" ,menu-bar-lookingglass-menu
                  :help "Visit imaginary websites"))
    (bindings--define-key menu [mi-menu-bar-paracosm-menu]
      `(menu-item "🧠Paracosm" ,menu-bar-paracosm-menu
                  :help "AI-assisted mind-mapping"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-utils-menu
  (let ((menu (make-sparse-keymap "Utilities")))
    (bindings--define-key menu [mi-pen-proxy-set-localhost]
      '(menu-item "Set proxy to localhost" pen-proxy-set-localhost
                  :help "For debugging the proxy"))
    (bindings--define-key menu [mi-pen-server-suggest]
      '(menu-item "Suggest server commands" pen-server-suggest
                  :help "When a human is prompted, it will appear in the hidden terminal"))
    (bindings--define-key menu [mi-pen-start-hidden-terminal]
      '(menu-item "Start hidden human terminal" pen-start-hidden-terminal
                  :help "When a human is prompted, it will appear in the hidden terminal"))
    (bindings--define-key menu [mi-pen-start-hidden-terminal-in-pet]
      '(menu-item "Start hidden human terminal in pet" pen-start-hidden-terminal-in-pet
                  :help "When a human is prompted, it will appear in the hidden terminal"))
    (bindings--define-key menu [mi-pen-start-pet-in-hidden-terminal]
      '(menu-item "Start pet in hidden human terminal (nice)" pen-start-pet-in-hidden-terminal
                  :help "When a human is prompted, it will appear in the hidden terminal"))
    (bindings--define-key menu [mi-menu-bar-khala-menu]
      `(menu-item "Khala" ,menu-bar-khala-menu
                  :help "Khala is an http server serving Pen.el endpoints"))
    (bindings--define-key menu [mi-menu-bar-pensieve-menu]
      `(menu-item "PenSieve" ,menu-bar-pensieve-menu
                  :help "Mount imaginary filesystems"))
    (bindings--define-key menu [mi-menu-bar-esp-menu]
      `(menu-item "ESP" ,menu-bar-esp-menu
                  :help "Language Server Protocol for any language or context"))
    (bindings--define-key menu [mi-menu-bar-inkwell-menu]
      `(menu-item "Inkw.el" ,menu-bar-inkwell-menu
                  :help "Propertised text encoding provenance"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-terminals-menu
  (let ((menu (make-sparse-keymap "Terminals")))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-demos-menu
  (let ((menu (make-sparse-keymap "Demos")))
    (bindings--define-key menu [mi-pen-demo-installation]
      '(menu-item "Installation of Pen.el" pen-demo-installation
                  :help "Demo the installation of Pen.el"))
    (bindings--define-key menu [mi-pen-demo-apostrophe]
      '(menu-item "Talking to chatbots with Apostrophe" pen-demo-apostrophe
                  :help "Demo talking to chatbots"))
    (bindings--define-key menu [mi-pen-demo-paracosm]
      '(menu-item "Mind-mapping with Paracosm" pen-demo-paracosm
                  :help "Mind-mapping with Augmented Intelligence"))
    (bindings--define-key menu [mi-pen-demo-human-promptee]
      '(menu-item "Human-Promptee" pen-demo-human-promptee
                  :help "A human as a promptee instead of a language model"))
    (bindings--define-key menu [mi-pen-demo-pet]
      '(menu-item "Pet vim" pen-demo-pet
                  :help "Running vim inside Pen.el"))
    (bindings--define-key menu [mi-pen-demo-imaginary-interpreter]
      '(menu-item "Imaginary Interpreter" pen-demo-imaginary-interpreter
                  :help "How to start and use an Imaginary Interpreter"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-pen-tutorials-menu
  (let ((menu (make-sparse-keymap "Help")))
    (bindings--define-key menu [mi-menu-bar-demos-menu]
      `(menu-item "Demos" ,menu-bar-demos-menu
                  :help "Talk 1-on-1 to chatbots"))
    (bindings--define-key menu [mi-pen-read-tutorial]
      '(menu-item "Blog posts" pen-read-tutorial
                  :help "Select from a bunch of tutorials"))
    ;; (bindings--define-key menu [mi-menu-bar-emacs-help-menu]
    ;;   `(menu-item "GNU/Emacs" ,menu-bar-emacs-help-menu
    ;;               :help "Standard Emacs Help menu"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-chatbots-menu
  (let ((menu (make-sparse-keymap "Chatbots")))
    (bindings--define-key menu [mi-menu-bar-apostrophe-menu]
      `(menu-item "Apostrophe" ,menu-bar-apostrophe-menu
                  :help "Talk 1-on-1 to chatbots"))
    (bindings--define-key menu [mi-menu-bar-mtp-menu]
      `(menu-item "Mad Tea-Party" ,menu-bar-mtp-menu
                  :help "Partake in simulated group conversation between chatbots and humans"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(defset menu-bar-common-menu
  (let ((menu (make-sparse-keymap "Common")))
    (bindings--define-key menu [mi-kill-buffer-and-window]
      '(menu-item "Kill buffer and window" kill-buffer-and-window
                  :help "Basic emacs command `kill-buffer-and-window`"))
    (bindings--define-key menu [mi-pen-define-general-knowledge]
      '(menu-item "Define word" pen-define-general-knowledge
                  :help "Define word under the cursor (topic: general knowledge)"))
    (bindings--define-key menu [mi-toggle-chrome]
      '(menu-item "Toggle minimal clutter mode" toggle-chrome
                  :help "Toggles line numbers, modeline and line wrap"))
    (bindings--define-key menu [mi-pen-run-prompt-function]
      '(menu-item "Run prompt function" pen-run-prompt-function
                  :help "Run a prompt function interactively"))
    (bindings--define-key menu [mi-pen-sps]
      '(menu-item "Split screen shell sensibly with shell (no cterm)" pen-sps
                  :help "Open a shell in a split screen sensibly"))
    (bindings--define-key menu [mi-pen-nbfs]
      '(menu-item "New empty file/buffer (*untitled*)" nbfs
                  :help "Open a new buffer without a name"))
    (bindings--define-key menu [mi-pen-tm-edit-v-in-nw]
      '(menu-item "Open in vim" pen-tm-edit-v-in-nw
                  :help "Open the current buffer in vim"))
    (bindings--define-key menu [mi-pen-tm-edit-pet-v-in-nw]
      '(menu-item "Open in pet vim" pen-tm-edit-pet-v-in-nw
                  :help "Open the current buffer in vim with an emacs eterm"))
    (bindings--define-key menu [mi-pen-term-sps]
      '(menu-item "Split screen with pet" pen-term-sps
                  :help "Open a pet in a split screen (emacs term inside docker)"))
    (bindings--define-key menu [pen-revert-kill-buffer-and-window]
      '(menu-item "Kill buffer / abort" pen-revert-kill-buffer-and-window
                  :help "This kills and discards the current buffer and window. It may be used to abort, when the human is prompted"))
    (bindings--define-key menu [pen-save-and-kill-buffer-window-and-emacsclient]
      '(menu-item "Save buffer and close" pen-save-and-kill-buffer-window-and-emacsclient
                  :help "Save and close the current buffer, and close the emacsclient. It may be used to confirm, save and continue, when the human is prompted"))
    (bindings--define-key menu [pen-complete-long]
      '(menu-item "Complete long" pen-complete-long
                  :help "Long-form completion"))
    (bindings--define-key menu [pen-complete-lines]
      '(menu-item "Complete lines" pen-complete-lines
                  :help "Complete a few lines"))
    (bindings--define-key menu [pen-complete-line]
      '(menu-item "Complete line" pen-complete-line
                  :help "Complete a line"))
    (bindings--define-key menu [pen-complete-words]
      '(menu-item "Complete words" pen-complete-words
                  :help "Complete a few words"))
    (bindings--define-key menu [pen-complete-word]
      '(menu-item "Complete word" pen-complete-word
                  :help "Complete a word"))
    (bindings--define-key menu [cancel-menu]
      '(menu-item "Cancel" identity-command
                  :help "Cancel out of this menu"))
    menu))

(if (pen-snq "inside-docker-p")
    (progn
      (bindings--define-key global-map [menu-bar file] nil)
      (bindings--define-key global-map [menu-bar edit] nil)
      (bindings--define-key global-map [menu-bar options] nil)
      ;; (bindings--define-key global-map [menu-bar buffers] nil)
      ;; (remove-hook 'menu-bar-update-hook 'menu-bar-update-buffers)
      (bindings--define-key global-map [menu-bar tools] nil)

      (bindings--define-key global-map [menu-bar pen]
        (cons "Pen.el" menu-bar-pen-menu))

      ;; (bindings--define-key global-map [menu-bar daemons]
      ;;   (cons "Daemons" menu-bar-daemons-menu))
      (bindings--define-key global-map [menu-bar daemons] nil)

      ;; (bindings--define-key global-map [menu-bar cterm]
      ;;   (cons "ct" menu-bar-cterm-menu))
      (bindings--define-key global-map [menu-bar cterm] nil)

      ;; (bindings--define-key global-map [menu-bar melee]
      ;;   (cons "Melee" menu-bar-melee-menu))
      (bindings--define-key global-map [menu-bar melee] nil)

      ;; (bindings--define-key global-map [menu-bar channel]
      ;;   (cons "Chann" menu-bar-channel-menu))
      (bindings--define-key global-map [menu-bar channel] nil)

      ;; (bindings--define-key global-map [menu-bar ii]
      ;;   (cons "𝑖i" menu-bar-ii-menu))
      (bindings--define-key global-map [menu-bar ii] nil)

      ;; (bindings--define-key global-map [menu-bar mtp]
      ;;   (cons "MTP" menu-bar-mtp-menu))
      (bindings--define-key global-map [menu-bar mtp] nil)

      ;; (bindings--define-key global-map [menu-bar paracosm]
      ;;   (cons "Cosm" menu-bar-paracosm-menu))
      (bindings--define-key global-map [menu-bar paracosm] nil)
      (bindings--define-key global-map [menu-bar apps] nil)
      (bindings--define-key global-map [menu-bar applications]
        (cons "Applications" menu-bar-apps-menu))

      (bindings--define-key global-map [menu-bar utilities]
        (cons "Utilities" menu-bar-utils-menu))

      (bindings--define-key global-map [menu-bar common]
        (cons "Common" menu-bar-common-menu))

      ;; (bindings--define-key global-map [menu-bar terminals]
      ;;   (cons "Terminals" menu-bar-terminals-menu))

      ;; (bindings--define-key global-map [menu-bar chatbots]
      ;;   (cons "Chatbots" menu-bar-chatbots-menu))

      ;; (bindings--define-key global-map [menu-bar esp]
      ;;   (cons "ESP" menu-bar-esp-menu))
      (bindings--define-key global-map [menu-bar esp] nil)

      ;; (bindings--define-key global-map [menu-bar prompts]
      ;;   (cons "Prompts" menu-bar-prompts-menu))
      (bindings--define-key global-map [menu-bar prompts] nil)

      ;; (bindings--define-key global-map [menu-bar engines]
      ;;   (cons "Engines" menu-bar-engines-menu))
      (bindings--define-key global-map [menu-bar engines] nil)

      ;; (bindings--define-key global-map [menu-bar engineering]
      ;;   (cons "Engineering" menu-bar-engineering-menu))
      (bindings--define-key global-map [menu-bar engineering] nil)

      (bindings--define-key global-map [menu-bar prompting]
        (cons "Prompting" menu-bar-prompting-menu))

      ;; (bindings--define-key global-map [menu-bar network]
      ;;   (cons "Network" menu-bar-network-menu))
      (bindings--define-key global-map [menu-bar network] nil)

      (bindings--define-key global-map [menu-bar config]
        (cons "Configure" menu-bar-configure-menu))

      (bindings--define-key global-map [menu-bar pen-help]
        (cons "Tutorials" menu-bar-pen-tutorials-menu))

      (bindings--define-key global-map [menu-bar documents]
        (cons "Documents" menu-bar-documents-menu))

      ;; (bindings--define-key global-map [menu-bar history]
      ;;   (cons "Hist" menu-bar-history-menu))
      (bindings--define-key global-map [menu-bar history] nil)

      ;; (bindings--define-key global-map [menu-bar inkwell]
      ;;   (cons "Ink" menu-bar-inkwell-menu))
      (bindings--define-key global-map [menu-bar inkwell] nil)

      ;; (bindings--define-key global-map [menu-bar lookingglass]
      ;;   (cons "LG" menu-bar-lookingglass-menu))
      (bindings--define-key global-map [menu-bar lookingglass] nil)

      ;; (bindings--define-key global-map [menu-bar pensieve]
      ;;   (cons "Sieve" menu-bar-pensieve-menu))
      (bindings--define-key global-map [menu-bar pensieve] nil)

      ;; (bindings--define-key global-map [menu-bar protocol]
      ;;   (cons "Protocol" menu-bar-protocol-menu))
      (bindings--define-key global-map [menu-bar protocol] nil)))

(require 'term)
;; tty-menu-exit is a c symbol

(defset tty-menu-navigation-map
  (let ((map (make-sparse-keymap)))
    ;; The next line is disabled because it breaks interpretation of
    ;; escape sequences, produced by TTY arrow keys, as tty-menu-*
    ;; commands.  Instead, we explicitly bind some keys to
    ;; tty-menu-exit.
    ;;(define-key map [t] 'tty-menu-exit)

    ;; The tty-menu-* are just symbols interpreted by term.c, they are
    ;; not real commands.
    (dolist (bind '((keyboard-quit . tty-menu-exit)
                    (keyboard-escape-quit . tty-menu-exit)
                    ;; The following two will need to be revised if we ever
                    ;; support a right-to-left menu bar.
                    (forward-char . tty-menu-next-menu)
                    (backward-char . tty-menu-prev-menu)
                    (right-char . tty-menu-next-menu)
                    (left-char . tty-menu-prev-menu)
                    (next-line . tty-menu-next-item)
                    (previous-line . tty-menu-prev-item)
                    (newline . tty-menu-select)
                    (newline-and-indent . tty-menu-select)
		                (menu-bar-open . tty-menu-exit)))
      (substitute-key-definition (car bind) (cdr bind)
                                 map (current-global-map)))

    ;; The bindings of menu-bar items are so that clicking on the menu
    ;; bar when a menu is already shown pops down that menu.
    (define-key map [menu-bar t] 'tty-menu-exit)

    (define-key map [?\C-r] 'tty-menu-select)
    (define-key map [?\C-j] 'tty-menu-select)
    (define-key map [return] 'tty-menu-select)
    (define-key map [linefeed] 'tty-menu-select)
    (menu-bar-define-mouse-key map 'mouse-1 'tty-menu-select)
    (menu-bar-define-mouse-key map 'drag-mouse-1 'tty-menu-select)
    (menu-bar-define-mouse-key map 'mouse-2 'tty-menu-select)
    (menu-bar-define-mouse-key map 'drag-mouse-2 'tty-menu-select)
    (menu-bar-define-mouse-key map 'mouse-3 'tty-menu-select)
    (menu-bar-define-mouse-key map 'drag-mouse-3 'tty-menu-select)
    (menu-bar-define-mouse-key map 'wheel-down 'tty-menu-next-item)
    (menu-bar-define-mouse-key map 'wheel-up 'tty-menu-prev-item)
    (menu-bar-define-mouse-key map 'wheel-left 'tty-menu-prev-menu)
    (menu-bar-define-mouse-key map 'wheel-right 'tty-menu-next-menu)
    ;; The following 6 bindings are for those whose text-mode mouse
    ;; lack the wheel.
    (menu-bar-define-mouse-key map 'S-mouse-1 'tty-menu-next-item)
    (menu-bar-define-mouse-key map 'S-drag-mouse-1 'tty-menu-next-item)
    (menu-bar-define-mouse-key map 'S-mouse-2 'tty-menu-prev-item)
    (menu-bar-define-mouse-key map 'S-drag-mouse-2 'tty-menu-prev-item)
    (menu-bar-define-mouse-key map 'S-mouse-3 'tty-menu-prev-item)
    (menu-bar-define-mouse-key map 'S-drag-mouse-3 'tty-menu-prev-item)
    ;; The down-mouse events must be bound to tty-menu-ignore, so that
    ;; only releasing the mouse button pops up the menu.
    (menu-bar-define-mouse-key map 'down-mouse-1 'tty-menu-ignore)
    ;; Don't change this until I can figure it out properly
    ;; For the moment, if in the terminal, drag across a menu item to select it
    ;; (menu-bar-define-mouse-key map 'down-mouse-1 'tty-menu-select)
    (menu-bar-define-mouse-key map 'down-mouse-2 'tty-menu-ignore)
    (menu-bar-define-mouse-key map 'down-mouse-3 'tty-menu-ignore)
    (menu-bar-define-mouse-key map 'C-down-mouse-1 'tty-menu-ignore)
    (menu-bar-define-mouse-key map 'C-down-mouse-2 'tty-menu-ignore)
    (menu-bar-define-mouse-key map 'C-down-mouse-3 'tty-menu-ignore)
    (menu-bar-define-mouse-key map 'mouse-movement 'tty-menu-mouse-movement)
    map))

(provide 'pen-menu-bar)