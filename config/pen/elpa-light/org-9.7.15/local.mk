
# Remove "oldorg:" to switch to "all" as the default target.
# Change "oldorg:" to an existing target to make that target the default,
# or define your own target here to become the default target.
oldorg:	# do what the old Makefile did by default.

##----------------------------------------------------------------------
##  CHECK AND ADAPT THE FOLLOWING DEFINITIONS
##----------------------------------------------------------------------

# Name of your emacs binary
EMACS	= emacs

# Where local software is found
prefix	= /usr/share

# Where local lisp files go.
lispdir= $(prefix)/emacs/site-lisp/org

# Where local data files go.
datadir = $(prefix)/emacs/etc/org

# Where info files go.
infodir = $(prefix)/info

# Define if you only need info documentation, the default includes html and pdf
#ORG_MAKE_DOC = info # html pdf

# Define which git branch to switch to during update.  Does not switch
# the branch when undefined.
GIT_BRANCH =

# Where to create temporary files for the testsuite
# respect TMPDIR if it is already defined in the environment
TMPDIR ?= /tmp
testdir = $(TMPDIR)/tmp-orgtest

# Configuration for testing
# Verbose ERT summary by default for Emacs-28 and above.
# To override:
# - Add to local.mk
#   EMACS_TEST_VERBOSE =
# - Export EMACS_TEST_VERBOSE environment variable with empty value
# - Run tests as
#   EMACS_TEST_VERBOSE= make test [OTHER_ARGUMENTS...]
#   or as
#   make test EMACS_TEST_VERBOSE= [OTHER_ARGUMENTS...]
EMACS_TEST_VERBOSE ?= yes
ifeq (,$(EMACS_TEST_VERBOSE))
# Emacs-28 considers empty value as true, fixed in Emacs-29
unexport EMACS_TEST_VERBOSE
endif
# add options before standard load-path
BTEST_PRE   =
# add options after standard load path
BTEST_POST  =
              # -L <path-to>/ert      # needed for Emacs23, Emacs24 has ert built in
              # -L <path-to>/ess      # needed for running R tests
              # -L <path-to>/htmlize  # need at least version 1.34 for source code formatting
BTEST_OB_LANGUAGES = awk C fortran maxima lilypond octave perl python java sqlite eshell calc
              # R                     # requires ESS to be installed and configured
              # ruby                  # requires inf-ruby to be installed and configured
# extra packages to require for testing
BTEST_EXTRA =
              # ess-site  # load ESS for R tests
# Whether to activate extra debugging facilities for make repro.
REPRO_DEBUG ?= yes
# Extra arguments passed to Emacs for make repro.
# e.g. -l config.el /tmp/bug.org
REPRO_ARGS ?=
# See default.mk for further configuration options.
