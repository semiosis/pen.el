(require 'easymenu)

(defmacro easy-menu-define (symbol maps doc menu)
  "Define a pop-up menu and/or menu bar menu specified by MENU.
If SYMBOL is non-nil, define SYMBOL as a function to pop up the
submenu defined by MENU, with DOC as its doc string.

MAPS, if non-nil, should be a keymap or a list of keymaps; add
the submenu defined by MENU to the keymap or each of the keymaps,
as a top-level menu bar item.

The first element of MENU must be a string.  It is the menu bar
item name.  It may be followed by the following keyword argument
pairs:

 :filter FUNCTION
    FUNCTION must be a function which, if called with one
    argument---the list of the other menu items---returns the
    items to actually display.

 :visible INCLUDE
    INCLUDE is an expression.  The menu is visible if the
    expression evaluates to a non-nil value.  `:included' is an
    alias for `:visible'.

 :active ENABLE
    ENABLE is an expression.  The menu is enabled for selection
    if the expression evaluates to a non-nil value.  `:enable' is
    an alias for `:active'.

 :label FORM
    FORM is an expression that is dynamically evaluated and whose
    value serves as the menu's label (the default is the first
    element of MENU).

 :help HELP
    HELP is a string, the help to display for the menu.
    In a GUI this is a \"tooltip\" on the menu button.  (Though
    in Lucid :help is not shown for the top-level menu bar, only
    for sub-menus.)

The rest of the elements in MENU are menu items.
A menu item can be a vector of three elements:

  [NAME CALLBACK ENABLE]

NAME is a string--the menu item name.

CALLBACK is a command to run when the item is chosen, or an
expression to evaluate when the item is chosen.

ENABLE is an expression; the item is enabled for selection if the
expression evaluates to a non-nil value.

Alternatively, a menu item may have the form:

   [ NAME CALLBACK [ KEYWORD ARG ]... ]

where NAME and CALLBACK have the same meanings as above, and each
optional KEYWORD and ARG pair should be one of the following:

 :keys KEYS
    KEYS is a string; a keyboard equivalent to the menu item.
    This is normally not needed because keyboard equivalents are
    usually computed automatically.  KEYS is expanded with
    `substitute-command-keys' before it is used.

 :key-sequence KEYS
    KEYS is a hint for speeding up Emacs's first display of the
    menu.  It should be nil if you know that the menu item has no
    keyboard equivalent; otherwise it should be a string or
    vector specifying a keyboard equivalent for the menu item.

 :active ENABLE
    ENABLE is an expression; the item is enabled for selection
    whenever this expression's value is non-nil.  `:enable' is an
    alias for `:active'.

 :visible INCLUDE
    INCLUDE is an expression; this item is only visible if this
    expression has a non-nil value.  `:included' is an alias for
    `:visible'.

 :label FORM
    FORM is an expression that is dynamically evaluated and whose
    value serves as the menu item's label (the default is NAME).

 :suffix FORM
    FORM is an expression that is dynamically evaluated and whose
    value is concatenated with the menu entry's label.

 :style STYLE
    STYLE is a symbol describing the type of menu item; it should
    be `toggle' (a checkbox), or `radio' (a radio button), or any
    other value (meaning an ordinary menu item).

 :selected SELECTED
    SELECTED is an expression; the checkbox or radio button is
    selected whenever the expression's value is non-nil.

 :help HELP
    HELP is a string, the help to display for the menu item.

Alternatively, a menu item can be a string.  Then that string
appears in the menu as unselectable text.  A string consisting
solely of dashes is displayed as a menu separator.

Alternatively, a menu item can be a list with the same format as
MENU.  This is a submenu."
  (declare (indent defun) (debug (symbolp body)) (doc-string 3))
  `(progn
     ,(if symbol `(defvar ,symbol nil ,doc))
     (easy-menu-do-define (quote ,symbol) ,maps ,doc ,menu)
     ;; my addition: return the symbol
     ',symbol))

(provide 'pen-easymenu)
