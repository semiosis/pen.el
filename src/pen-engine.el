;; pen-engine allows you to configure the engines you want
;; For example, you may only want to use free(libre) engines, or private(local) engines, or powerful(openai) engines.

;; It should also provide redundancy
;; Detect what engines are available and select one

(require 'pen-configure)

;; TODO Make it so
;; - If a prompt requests more tokens than the engine can provide, find an appropriate engine



;; Forcing engines is not generally recommended
;; I should really make a tree of engines which can act as fall-backs

(defcustom pen-force-engine ""
  "Force using this engine"
  :type 'string
  :group 'pen
  :options (ht-keys pen-engines)
  :set (lambda (_sym value)
         (set _sym value))
  :get (lambda (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-force-engine-disabled nil
  "Do not allow prompts to override the engine override"
  :type 'boolean
  :group 'pen
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defun engine-available-p (name)
  "Each engine has a predicate to determine if you can use it."

  ;; If the engine has loaded availability-test then use it,
  ;; otherwise return true

  (let* ((e (ht-get pen-engines name))
         (availability-test (ht-get e "availability-test")))

    (if availability-test
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (pen-snq availability-test)
          (pen-snq (concat "export PEN_CACHE=y; " availability-test)))
      t)))

(defun test-engine-available ()
  (interactive)
  (engine-available-p "OpenAI Davinci Code Edit"))

(provide 'pen-engine)
