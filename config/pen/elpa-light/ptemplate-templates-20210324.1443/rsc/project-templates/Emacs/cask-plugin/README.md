# About

Template to generate an Emacs cask project from scratch, with the following
content:
- A Caskfile, set up with ELPA/MELPA, pointing to the plugin's .el file in
  `(package-file)` and depending on ert-runner for development
- A <project-name>.el file, with all necessary comments (ends here, …)
  (interactive snippet) and some package metadata (Author, Version, …)
  
# Configuration

This configuration makes use of the `ptemplate-templates-repository-url-format`
(which see) variable to derive the `URL:` package attribute.
