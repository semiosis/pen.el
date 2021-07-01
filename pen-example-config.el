;; https://github.com/perfectayush/emacs-yamlmod
(if module-file-suffix
    (progn
      (module-load "/home/shane/source/git/config/emacs/manual-packages/emacs-yamlmod/target/release/libyamlmod.so")
      (add-to-list 'load-path "/home/shane/source/git/config/emacs/manual-packages/emacs-yamlmod")
      (require 'yamlmod)
      (require 'yamlmod-wrapper)))