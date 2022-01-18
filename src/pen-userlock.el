(defun ask-user-about-lock (file opponent)
  "Ask user what to do when he wants to edit FILE but it is locked by OPPONENT.
This function has a choice of three things to do:
  do (signal \\='file-locked (list FILE OPPONENT))
    to refrain from editing the file
  return t (grab the lock on the file)
  return nil (edit the file even though it is locked).
You can redefine this function to choose among those three alternatives
in any way you like."
  (discard-input)
  t)

(provide 'pen-userlock)