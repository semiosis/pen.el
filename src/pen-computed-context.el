;; A dictionary of keys and values should be created as a local variable, through logic
;; Why not just merely use local variables instead of storing inside a local dictionary?
;; I would only do this for organizational purposes, but it's really not necessary at all and make overcomplicate things
;; - default google keywords

;; recompute at certain times. For example, when opening a file or switching to a different buffer
;; The glossary system should really be relying on this to determine the topics.

;; This file should compute topics, perhaps using NLP, for which corresponding glossaries may then be added.
;; Upon opening, compute the topics.
;; The glossary system should then query the topics.
;; Take code out of the glossary system and place it here

(provide 'pen-computed-context)