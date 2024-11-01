(require 'oai-files)
(require 'oai-engines)

;; https://beta.openai.com/docs/api-reference/fine-tunes/

;; Steps
;; 1 Prepare and upload training data
;; 2 Train a new fine-tuned model
;; 3 Use your fine-tuned model

;; (json-encode-list '(("prompt" "completion") ("prompt2" "completion")))
;; The question is: are completions coming quick extend beyond completion and is more like transformation?
;; This is what the prompt should encode anyway, so I'll do that.
;; (json-encode-list '(("prompt" . "once upon a time") ("completion" "once upon a time there was a frog")))
;; (json-encode-list '(("prompt" . "once upon a time") ("completion" . "there was a frog")))

;; davinci and codex require special access
;; defset not available
(defvar oai-ft-engines
  '("ada" "babbage" "curie" "davinci" "davinci-codex"))

(defvar oai-ft-training-data-testset
  '((("prompt" . "once upon a time") ("completion" . "there was a frog"))
    (("prompt" . "about a") ("completion" . "frog"))))

;; TODO Run this and collect the output
(defun openai-prepare-data (prompt-completion-tuples)
  "This tool accepts different formats, with the only requirement that they contain a prompt
and a completion column/key. You can pass a CSV, TSV, XLSX, JSON or JSONL file, and it
will save the output into a JSONL file ready for fine-tuning, after guiding you through
the process of suggested changes."
  (let ((fp
         (cond
          ((and
            (stringp prompt-completion-tuples)
            (f-file-p prompt-completion-tuples)) prompt-completion-tuples)
          ((listp prompt-completion-tuples)
           (make-temp-file
            "oai-ft-" nil "txt"
            (list2str
             (cl-loop for tp in prompt-completion-tuples collect (json-encode-alist tp))))))))
    ;; (find-file fp)
    ;; (pen-snc (cmd "pen-openai-official" "tools" "fine_tunes.prepare_data" "-f" prompt-completion-tuples))
    (etv (cmd "pen-openai-official" "tools" "fine_tunes.prepare_data" "-f" fp))))

(defmacro comment (&rest body) nil)

(comment
 (openai-prepare-data oai-ft-training-data-testset))

(defun openai-fine-tune-prepare (train-file-id-or-path base-model)
  "Where BASE_MODEL is the name of the base model you're starting from (ada, babbage, or
curie). Note that if you're fine-tuning a model for a classification task, you should
also set the parameter --no_packing.

Running this does several things:

1 Uploads the file using the files API (or uses an already-uploaded file)
2 Creates a fine-tune job
3 Streams events until the job is done (this often takes minutes, but can take hours if
 there are many jobs in the queue or your dataset is large)"
  (cmd "pen-openai-official" "api" "fine_tunes.create" "-t" train-file-id-or-path "-m" base-model))

(defun oai-ft-list-json ()
  (pen-snc "pen-openai-official api fine_tunes.list"))

(defun oai-ft-job-state (job-id)
  (pen-snc (cmd "pen-openai-official" "api" "fine_tunes.get" "-i" job-id)))

(defun oai-ft-job-cancel (job-id)
  (pen-snc (cmd "pen-openai-official" "api" "fine_tunes.cancel" "-i" job-id)))

(defun oai-ft-job-events (job-id)
  (pen-snc (cmd "pen-openai-official" "api" "fine_tunes.events" "-i" job-id)))

(provide 'oai-finetuning)