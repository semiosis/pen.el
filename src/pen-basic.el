(require 'basic-mode)

(comment
 (load "pen-basic"))

(define-derived-mode visual-basic-mode basic-qb45-mode "Visual lBasic"
  "Programming mode for Microsoft Visual Basic.
Derived from `basic-mode'."

  ;; Notes:

  ;; * DATE$, MID$, PEN, PLAY, SCREEN, SEEK, STRIG, TIMER, and TIME$
  ;;   are both functions and statements, and are only highlighted as
  ;;   one or the other.

  ;; * $DYNAMIC, $INCLUDE, and $STATIC meta commands are not highlighted
  ;;   because they must appear in a comment.

  ;; * LOCAL, and SIGNAL are reserved for future use.

  ;; * The 'FOR' in 'OPEN "FILE" FOR OUTPUT AS #1' is highlighted the
  ;;   same as in FOR loop (a keyword). Should it be?

  (setq basic-builtins
        '("absolute" "access" "alias" "append" "beep" "binary" "bload"
          "bsave" "byval" "cdecl" "chdir" "circle" "clear" "close"
          "optional"
          "cls" "color" "com" "const" "data" "draw" "environ" "erase"
          "error" "field" "files" "get" "input" "input #" "ioctl"
          "interrupt" "key" "kill" "let" "line" "list" "locate" "lock"
          "lprint" "lset" "mkdir"
          ;; "name"
          "open" "out" "output" "paint"
          "palette" "pcopy" "peek" "pen" "play" "poke" "preset" "print"
          "print #" "pset" "put" "random" "randomize" "read" "reset"
          "restore" "rmdir" "rset" "run" "screen" "seek" "shared" "sound"
          "static" "strig" "swap" "timer" "uevent" "unlock" "using" "view"
          "wait" "width" "window" "write" "write #"))

  (setq basic-functions
        '("abs" "and" "asc" "atn" "cdbl" "chr$" "cint" "clng" "command$"
          "cos" "csng" "csrlin" "cvd" "cvdmbf" "cvi" "cvl" "cvs" "cvsmbf"
          "date$" "environ$" "eof" "eqv" "erdev" "erdev$" "erl" "err"
          "exp" "fileattr" "fix" "fre" "freefile" "hex$" "imp" "inkey$"
          "inp" "input$" "instr" "int" "ioctl$" "lbound" "lcase$" "left$"
          "len" "loc" "lof" "log" "lpos" "ltrim$" "mid$" "mkd$" "mkdmbf$"
          "mki$" "mkl$" "mks$" "mksmbf$" "mod" "not" "oct$" "or" "pmap"
          "point" "pos" "right$" "rnd" "rtrim$" "sadd" "setmem" "sgn"
          "sin" "space$" "spc" "sqr" "stick" "str$" "string$" "tab" "tan"
          "time$" "ubound" "ucase$" "val" "varptr" "varptr$" "varseg"
          "xor"))

  ;; [[sps:carbonyl "https://www.tek-tips.com/threads/vb-reserved-words-full-list.657462/"]]

  ;; VB Reserved Words Full List 
  ;; Here's a complete list as provided by MS on some obscure location of their website!
  ;; ("Abs" "Access" "AddItem" "AddNew" "Alias" "And" "Any" "App" "AppActivate"
  ;;  "Append" "AppendChunk" "Arrange" "As" "Asc" "Atn" "Base" "Beep" "BeginTrans"
  ;;  "Binary" "ByVal" "Call" "Case" "CCur" "CDbl" "ChDir" "ChDrive" "Chr" "Chr$"
  ;;  "CInt" "Circle" "Clear" "Clipboard" "CLng" "Close" "Cls" "Command" "Command$"
  ;;  "CommitTrans" "Compare" "Const" "Control" "Controls" "Cos" "CreateDynaset"
  ;;  "CSng" "CStr" "CurDir$" "Currency" "CVar" "CVDate" "" "Data" "Date" "Date$"
  ;;  "DateSerial" "DateValue" "Day" "Debug" "Declare" "DefCur" "CefDbl" "DefInt"
  ;;  "DefLng" "DefSng" "DefStr" "DefVar" "Delete" "Dim" "Dir" "Dir$" "Do" "DoEvents"
  ;;  "Double" "Drag" "Dynaset" "Edit" "Else" "ElseIf" "End" "EndDoc" "EndIf"
  ;;  "Environ$" "EOF" "Eqv" "Erase" "Erl" "Err" "Error" "Error$" "ExecuteSQL" "Exit"
  ;;  "Exp" "Explicit" "False" "FieldSize" "FileAttr" "FileCopy" "FileDateTime"
  ;;  "FileLen" "Fix" "For" "Form" "Format" "Format$" "Forms" "FreeFile" "Function"
  ;;  "Get" "GetAttr" "GetChunk" "GetData" "DetFormat" "GetText" "Global" "GoSub"
  ;;  "GoTo" "Hex" "Hex$" "Hide" "Hour" "If" "Imp" "Input" "Input$" "InputBox"
  ;;  "InputBox$" "InStr" "Int" "Integer" "Is" "IsDate" "IsEmpty" "IsNull"
  ;;  "IsNumeric" "Kill" "LBound" "LCase" "LCase$" "Left" "Left$" "Len" "Let" "Lib"
  ;;  "Like" "Line" "LinkExecute" "LinkPoke" "LinkRequest" "LinkSend" "Load"
  ;;  "LoadPicture" "Loc" "Local" "Lock" "LOF" "Log" "Long" "Loop" "LSet" "LTrim"
  ;;  "LTrim$" "Me" "Mid" "Mid$" "Minute" "MkDir" "Mod" "Month" "Move" "MoveFirst"
  ;;  "MoveLast" "MoveNext" "MovePrevious" "MoveRelative" "MsgBox" "Name" "New"
  ;;  "NewPage" "Next" "NextBlock" "Not" "Nothing" "Now" "Null" "Oct" "Oct$" "On"
  ;;  "Open" "OpenDataBase" "Option" "Or" "Output" "Point" "Preserve" "Print"
  ;;  "Printer" "PrintForm" "Private" "PSet" "Put" "QBColor" "Random" "Randomize"
  ;;  "Read" "ReDim" "Refresh" "RegisterDataBase" "Rem" "RemoveItem" "Reset"
  ;;  "Restore" "Resume" "Return" "RGB" "Right" "Right$" "RmDir" "Rnd" "Rollback"
  ;;  "RSet" "RTrim" "RTrim$" "SavePicture" "Scale" "Second" "Seek" "Select"
  ;;  "SendKeys" "Set" "SetAttr" "SetData" "SetFocus" "SetText" "Sgn" "Shared"
  ;;  "Shell" "Show" "Sin" "Single" "Space" "Space$" "Spc" "Sqr" "Static" "Step"
  ;;  "Stop" "Str" "Str$" "StrComp" "String" "String$" "Sub" "System" "Tab" "Tan"
  ;;  "Text" "TextHeight" "TextWidth" "Then" "Time" "Time$" "Timer" "TimeSerial"
  ;;  "TimeValue" "To" "Trim" "Trim$" "True" "Type" "TypeOf" "UBound" "UCase"
  ;;  "UCase$" "Unload" "Unlock" "Until" "Update" "Using" "Val" "Variant" "VarType"
  ;;  "Weekday" "Wend" "While" "Width" "Write" "Xor" "Year" "ZOrder")
  ;;That list is not complete with respect to VB6. Right off, I see three intrinsic functions missing - InStrRev, Join and Split.

  (setq basic-keywords
        '("as" "call" "calls" "case" "chain" "common" "declare" "def"
          "def seg" "defdbl" "defint" "deflng" "defsng" "defstr" "dim"
          "do" "else" "elseif" "end" "endif" "exit" "for" "fn" "function"
          "gosub" "goto" "if" "is" "loop" "next" "off" "on" "on com"
          "on local error"
          "on error" "on key" "on pen" "on play" "on strig" "on timer"
          "on uevent" "option base" "redim" "preserve"
          "resume" "return" "select"
          "shell" "sleep" "step" "stop" "sub"
          "system"
          "then" "to"
          "type" "until" "wend" "while" "with" "option explicit" "attribute"
          "enum"
          "public" "private" "property"
          "set" "nothing"))

  (setq basic-types
        '("any" "double" "integer" "long" "single" "string"
          "boolean" "object" "variant"))

  (setq basic-increase-indent-keywords-bol
        '("case" "do" "for" "function" "repeat" "sub" "select" "while" "enum"
          "public" "private"))
  (setq basic-increase-indent-keywords-eol
        '("else" "then"))
  (setq basic-decrease-indent-keywords-bol
        '("case" "else" "elseif" "end" "loop" "next" "until" "wend"))

  ;; Shorter than "REM"
  (setq-local comment-start "'")

  ;; Treat . and # as part of identifier ("input #" etc)
  (modify-syntax-entry ?. "w   " basic-mode-syntax-table)
  (modify-syntax-entry ?# "w   " basic-mode-syntax-table)

  (basic-mode-initialize))

(define-derived-mode basic-generic-mode visual-basic-mode "Basic[Generic]"
  "Generic BASIC programming mode.
This is the default mode that will be used if no sub mode is specified.
Derived from `visual-basic-mode'.  For more information, see `basic-mode'."
  (basic-mode-initialize))

(provide 'pen-basic)
