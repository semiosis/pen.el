;;; evil-fringe-mark-overlays.el --- Character overlays for evil-fringe-mark
;; This file is not part of GNU Emacs.

;; Copyright (C) 2019 Andrew Smith

;; Author: Andrew Smith <andy.bill.smith@gmail.com>
;; URL: https://github.com/Andrew-William-Smith/evil-fringe-mark
;; Version: 1.2.1
;; Package-Requires: ((emacs "24.3") (evil "1.0.0") (fringe-helper "0.1.1") (goto-chg "1.6"))

;; This file is part of evil-fringe-mark.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Code:
(require 'fringe-helper)
(fringe-helper-define 'evil-fringe-mark-upper-a '(center)
  "...XX..."
  "..XXXX.."
  ".XXXXXX."
  "XXX..XXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXXXXXXX"
  "XXXXXXXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-upper-b '(center)
  "XXXXXXX."
  "XXXXXXXX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XXXXXX."
  ".XXXXXX."
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  "XXXXXXXX"
  "XXXXXXX.")

(fringe-helper-define 'evil-fringe-mark-upper-c '(center)
  "..XXXXX."
  ".XXXXXXX"
  "XXX...XX"
  "XX.....X"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX.....X"
  "XXX...XX"
  ".XXXXXXX"
  "..XXXXX.")

(fringe-helper-define 'evil-fringe-mark-upper-d '(center)
  "XXXXXX.."
  "XXXXXXX."
  ".XX..XXX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX..XXX"
  "XXXXXXX."
  "XXXXXX..")

(fringe-helper-define 'evil-fringe-mark-upper-e '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  ".XX...XX"
  ".XX....X"
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX..X.."
  ".XXXXX.."
  ".XXXXX.."
  ".XX..X.."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....X"
  ".XX...XX"
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-upper-f '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  ".XX...XX"
  ".XX....X"
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX..X.."
  ".XXXXX.."
  ".XXXXX.."
  ".XX..X.."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  "XXXX...."
  "XXXX....")

(fringe-helper-define 'evil-fringe-mark-upper-g '(center)
  "..XXXXX."
  ".XXXXXXX"
  "XXX...XX"
  "XX.....X"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX..XXXX"
  "XX..XXXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX...XX"
  ".XXXXXXX"
  "..XXX.XX")

(fringe-helper-define 'evil-fringe-mark-upper-h '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXXXXXXX"
  "XXXXXXXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-upper-i '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-upper-j '(center)
  "..XXXXXX"
  "..XXXXXX"
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "X...XX.."
  "XX..XX.."
  "XXXXX..."
  ".XXX....")

(fringe-helper-define 'evil-fringe-mark-upper-k '(center)
  "XX....XX"
  "XX....XX"
  "XX...XX."
  "XX...XX."
  "XX..XX.."
  "XX..XX.."
  "XX.XX..."
  "XX.XX..."
  "XXXX...."
  "XXXX...."
  "XX.XX..."
  "XX.XX..."
  "XX..XX.."
  "XX..XX.."
  "XX...XX."
  "XX...XX."
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-upper-l '(center)
  "XXXX...."
  "XXXX...."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....X"
  ".XX...XX"
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-upper-m '(center)
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  "XXX..XXX"
  "XXX..XXX"
  "XXXXXXXX"
  "XXXXXXXX"
  "XXXXXXXX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-upper-n '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX...XX"
  "XXX...XX"
  "XXXX..XX"
  "XXXX..XX"
  "XXXX..XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX..XXXX"
  "XX..XXXX"
  "XX..XXXX"
  "XX...XXX"
  "XX...XXX"
  "XX....XX"
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-upper-o '(center)
  "..XXXX.."
  ".XXXXXX."
  "XXX..XXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  ".XXXXXX."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-upper-p '(center)
  "XXXXX..."
  "XXXXXX.."
  ".XX..XX."
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX..XX."
  ".XXXXX.."
  ".XXXX..."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  "XXXX...."
  "XXXX....")

(fringe-helper-define 'evil-fringe-mark-upper-q '(center)
  "..XXXX.."
  ".XXXXXX."
  "XXX..XXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XXXXXXXX"
  ".XXXXXX."
  "..XXXXX."
  ".....XXX"
  "......XX")

(fringe-helper-define 'evil-fringe-mark-upper-r '(center)
  "XXXXX..."
  "XXXXXX.."
  ".XX..XX."
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX..XX."
  ".XXXXX.."
  ".XXXX..."
  ".XXXX..."
  ".XX.XX.."
  ".XX.XX.."
  ".XX..XX."
  ".XX..XX."
  ".XX...XX"
  "XXXX..XX"
  "XXXX..XX")

(fringe-helper-define 'evil-fringe-mark-upper-s '(center)
  "..XXXX.."
  ".XXXXXX."
  "XX....XX"
  "XX.....X"
  "XX......"
  "XX......"
  "XXX....."
  ".XXX...."
  "..XXX..."
  "...XXX.."
  "....XXX."
  ".....XXX"
  "......XX"
  "......XX"
  "X.....XX"
  "XX....XX"
  ".XXXXXX."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-upper-t '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  "XX.XX.XX"
  "X..XX..X"
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "..XXXX.."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-upper-u '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  "XXXXXXXX"
  ".XXXXXX.")

(fringe-helper-define 'evil-fringe-mark-upper-v '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  ".XX..XX."
  ".XX..XX."
  "..XXXX.."
  "..XXXX.."
  "...XX...")

(fringe-helper-define 'evil-fringe-mark-upper-w '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XXXXXXXX"
  ".XXXXXX."
  ".XX..XX."
  "..X..X..")

(fringe-helper-define 'evil-fringe-mark-upper-x '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  ".XX..XX."
  ".XX..XX."
  ".XX..XX."
  "..XXXX.."
  "..XXXX.."
  "...XX..."
  "...XX..."
  "..XXXX.."
  "..XXXX.."
  ".XX..XX."
  ".XX..XX."
  ".XX..XX."
  "XX....XX"
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-upper-y '(center)
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  ".XX..XX."
  ".XX..XX."
  "..XXXX.."
  "..XXXX.."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "..XXXX.."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-upper-z '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  "XX....XX"
  "X.....XX"
  ".....XXX"
  ".....XX."
  "....XXX."
  "....XX.."
  "...XXX.."
  "...XX..."
  "..XXX..."
  "..XX...."
  ".XXX...."
  ".XX....."
  "XXX....X"
  "XX....XX"
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-lower-a '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  ".XXXXX.."
  "XXXXXXX."
  "XX...XX."
  "X....XX."
  ".....XX."
  ".XXXXXX."
  "XXXXXXX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XXXXXXXX"
  ".XXXX.XX")

(fringe-helper-define 'evil-fringe-mark-lower-b '(center)
  "XXX....."
  "XXX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XXXXX.."
  ".XXXXXX."
  ".XX..XXX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX..XXX"
  "XXXXXXX."
  "XX.XXX..")

(fringe-helper-define 'evil-fringe-mark-lower-c '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "..XXXXX."
  ".XXXXXXX"
  "XXX...XX"
  "XX.....X"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX.....X"
  "XXX...XX"
  ".XXXXXXX"
  "..XXXXX.")

(fringe-helper-define 'evil-fringe-mark-lower-d '(center)
  ".....XXX"
  ".....XXX"
  ".....XX."
  ".....XX."
  ".....XX."
  ".....XX."
  "..XXXXX."
  ".XXXXXX."
  "XXX..XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XXX..XX."
  ".XXXXXXX"
  "..XXX.XX")

(fringe-helper-define 'evil-fringe-mark-lower-e '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "..XXXXX."
  ".XXXXXXX"
  "XXX...XX"
  "XX....XX"
  "XX....XX"
  "XXXXXXXX"
  "XXXXXXXX"
  "XX......"
  "XX......"
  "XXX...XX"
  ".XXXXXXX"
  "..XXXXX.")

(fringe-helper-define 'evil-fringe-mark-lower-f '(center)
  "..XXXXX."
  ".XXXXXXX"
  ".XXX..XX"
  ".XX....X"
  ".XX....."
  ".XX....."
  ".XX....."
  "XXXXXX.."
  "XXXXXX.."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  "XXXX...."
  "XXXX....")

(fringe-helper-define 'evil-fringe-mark-lower-g '(center)
  "........"
  "........"
  "........"
  "..XXX.XX"
  ".XXXXXXX"
  "XXX..XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XXX..XX."
  ".XXXXXX."
  "..XXXXX."
  ".....XX."
  "XX...XX."
  "XXX..XX."
  ".XXXXXX."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-lower-h '(center)
  "XXX....."
  "XXX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX.XX.."
  ".XXXXXX."
  ".XXXXXXX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  "XXX...XX"
  "XXX...XX")

(fringe-helper-define 'evil-fringe-mark-lower-i '(center)
  "........"
  "...XX..."
  "..XXXX.."
  "...XX..."
  "........"
  "........"
  ".XXXX..."
  ".XXXX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  ".XXXXXX."
  ".XXXXXX.")

(fringe-helper-define 'evil-fringe-mark-lower-j '(center)
  "....XX.."
  "...XXXX."
  "....XX.."
  "........"
  "........"
  "..XXXX.."
  "..XXXX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "....XX.."
  "X...XX.."
  "XX.XXX.."
  "XXXXX..."
  ".XXX....")

(fringe-helper-define 'evil-fringe-mark-lower-k '(center)
  "XXX....."
  "XXX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX...XX"
  ".XX..XX."
  ".XX.XX.."
  ".XXXX..."
  ".XXX...."
  ".XXXX..."
  ".XX.XX.."
  ".XX.XX.."
  ".XX..XX."
  ".XX..XX."
  "XXX...XX"
  "XXX...XX")

(fringe-helper-define 'evil-fringe-mark-lower-l '(center)
  ".XXXX..."
  ".XXXX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  ".XXXXXX."
  ".XXXXXX.")

(fringe-helper-define 'evil-fringe-mark-lower-m '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XXX..XX."
  "XXXXXXXX"
  "XXXXXXXX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX")

(fringe-helper-define 'evil-fringe-mark-lower-n '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XXX.XXX."
  "XXXXXXXX"
  ".XXX.XXX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  "XXX...XX"
  "XXX...XX")

(fringe-helper-define 'evil-fringe-mark-lower-o '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "..XXXX.."
  ".XXXXXX."
  "XXX..XXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  ".XXXXXX."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-lower-p '(center)
  "........"
  "........"
  "........"
  "XX.XXX.."
  "XXXXXXX."
  ".XX..XXX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX...XX"
  ".XX..XXX"
  ".XXXXXX."
  ".XXXXX.."
  ".XX....."
  ".XX....."
  ".XX....."
  "XXX....."
  "XXX.....")

(fringe-helper-define 'evil-fringe-mark-lower-q '(center)
  "........"
  "........"
  "........"
  "..XXX.XX"
  ".XXXXXXX"
  "XXX..XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XXX..XX."
  ".XXXXXX."
  "..XXXXX."
  ".....XX."
  ".....XX."
  ".....XX."
  ".....XXX"
  ".....XXX")

(fringe-helper-define 'evil-fringe-mark-lower-r '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XXX.XXX."
  "XXXXXXXX"
  ".XXX..XX"
  ".XX...XX"
  ".XX....X"
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  ".XX....."
  "XXXX...."
  "XXXX....")

(fringe-helper-define 'evil-fringe-mark-lower-s '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "..XXXX.."
  ".XXXXXX."
  "XX....XX"
  "XX.....X"
  "XXX....."
  "XXXXXX.."
  "..XXXXX."
  "......XX"
  "X.....XX"
  "XX....XX"
  ".XXXXXX."
  "..XXXX..")

(fringe-helper-define 'evil-fringe-mark-lower-t '(center)
  "........"
  "........"
  "...X...."
  "..XX...."
  "..XX...."
  "..XX...."
  "..XX...."
  "XXXXXXX."
  "XXXXXXX."
  "..XX...."
  "..XX...."
  "..XX...."
  "..XX...."
  "..XX...."
  "..XX...X"
  "..XXX.XX"
  "..XXXXXX"
  "...XXXX.")

(fringe-helper-define 'evil-fringe-mark-lower-u '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XX...XX."
  "XXX.XXX."
  "XXXXXXXX"
  ".XXX.XXX")

(fringe-helper-define 'evil-fringe-mark-lower-v '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX..XXX"
  ".XX..XX."
  "..XXXX.."
  "..XXXX.."
  "...XX...")

(fringe-helper-define 'evil-fringe-mark-lower-w '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XX.XX.XX"
  "XXXXXXXX"
  ".XXXXXX."
  ".XX..XX."
  "..X..X..")

(fringe-helper-define 'evil-fringe-mark-lower-x '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XX....XX"
  "XX....XX"
  ".XX..XX."
  ".XX..XX."
  "..XXXX.."
  "...XX..."
  "...XX..."
  "..XXXX.."
  ".XX..XX."
  ".XX..XX."
  "XX....XX"
  "XX....XX")

(fringe-helper-define 'evil-fringe-mark-lower-y '(center)
  "........"
  "........"
  "........"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXX...XX"
  ".XXXXXXX"
  "..XXXXXX"
  "......XX"
  "......XX"
  ".....XXX"
  "....XXX."
  "XXXXXX.."
  "XXXXX...")

(fringe-helper-define 'evil-fringe-mark-lower-z '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "XXXXXXXX"
  "XXXXXXXX"
  "XX....XX"
  "......XX"
  ".....XXX"
  "....XXX."
  "...XXX.."
  "..XXX..."
  ".XXX...."
  "XXX...XX"
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-symbol-period '(center)
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "...XX..."
  "..XXXX.."
  ".XXXXXX."
  "..XXXX.."
  "...XX...")

(fringe-helper-define 'evil-fringe-mark-symbol-caron '(center)
  "...XX..."
  "..XXXX.."
  ".XXXXXX."
  "XXX..XXX"
  "XX....XX"
  "X......X"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........"
  "........")

(fringe-helper-define 'evil-fringe-mark-symbol-lt '(center)
  "........"
  ".......X"
  "......XX"
  ".....XXX"
  "....XXX."
  "...XXX.."
  "..XXX..."
  ".XXX...."
  "XXX....."
  "XXX....."
  ".XXX...."
  "..XXX..."
  "...XXX.."
  "....XXX."
  ".....XXX"
  "......XX"
  ".......X"
  "........")

(fringe-helper-define 'evil-fringe-mark-symbol-gt '(center)
  "........"
  "X......."
  "XX......"
  "XXX....."
  ".XXX...."
  "..XXX..."
  "...XXX.."
  "....XXX."
  ".....XXX"
  ".....XXX"
  "....XXX."
  "...XXX.."
  "..XXX..."
  ".XXX...."
  "XXX....."
  "XX......"
  "X......."
  "........")

(fringe-helper-define 'evil-fringe-mark-symbol-gtlt '(center)
  "....XXX"
  "...XXX."
  "..XXX.."
  ".XXX..."
  "XXX...."
  ".XXX..."
  "..XXX.."
  "...XXX."
  "....XXX"
  "XXX...."
  ".XXX..."
  "..XXX.."
  "...XXX."
  "....XXX"
  "...XXX."
  "..XXX.."
  ".XXX..."
  "XXX....")

(fringe-helper-define 'evil-fringe-mark-symbol-lcurly '(center)
  ".....XXX"
  "....XXXX"
  "...XXX.."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "..XXX..."
  "XXXX...."
  "XXXX...."
  "..XXX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XXX.."
  "....XXXX"
  ".....XXX")

(fringe-helper-define 'evil-fringe-mark-symbol-rcurly '(center)
  "XXX....."
  "XXXX...."
  "..XXX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XXX.."
  "....XXXX"
  "....XXXX"
  "...XXX.."
  "...XX..."
  "...XX..."
  "...XX..."
  "...XX..."
  "..XXX..."
  "XXXX...."
  "XXX.....")

(fringe-helper-define 'evil-fringe-mark-symbol-lsquare '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XX......"
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-symbol-rsquare '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "......XX"
  "XXXXXXXX"
  "XXXXXXXX")

(fringe-helper-define 'evil-fringe-mark-symbol-lrsquare '(center)
  "XXXXXXXX"
  "XXXXXXXX"
  "XX......"
  "XX......"
  "XX..XXXX"
  "XX..XXXX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XX....XX"
  "XXXX..XX"
  "XXXX..XX"
  "......XX"
  "......XX"
  "XXXXXXXX"
  "XXXXXXXX")


(defvar evil-fringe-mark-bitmaps '(( 46 . evil-fringe-mark-symbol-period)
                                   ( 60 . evil-fringe-mark-symbol-lt)
                                   ( 62 . evil-fringe-mark-symbol-gt)
                                   ( 65 . evil-fringe-mark-upper-a)
                                   ( 66 . evil-fringe-mark-upper-b)
                                   ( 67 . evil-fringe-mark-upper-c)
                                   ( 68 . evil-fringe-mark-upper-d)
                                   ( 69 . evil-fringe-mark-upper-e)
                                   ( 70 . evil-fringe-mark-upper-f)
                                   ( 71 . evil-fringe-mark-upper-g)
                                   ( 72 . evil-fringe-mark-upper-h)
                                   ( 73 . evil-fringe-mark-upper-i)
                                   ( 74 . evil-fringe-mark-upper-j)
                                   ( 75 . evil-fringe-mark-upper-k)
                                   ( 76 . evil-fringe-mark-upper-l)
                                   ( 77 . evil-fringe-mark-upper-m)
                                   ( 78 . evil-fringe-mark-upper-n)
                                   ( 79 . evil-fringe-mark-upper-o)
                                   ( 80 . evil-fringe-mark-upper-p)
                                   ( 81 . evil-fringe-mark-upper-q)
                                   ( 82 . evil-fringe-mark-upper-r)
                                   ( 83 . evil-fringe-mark-upper-s)
                                   ( 84 . evil-fringe-mark-upper-t)
                                   ( 85 . evil-fringe-mark-upper-u)
                                   ( 86 . evil-fringe-mark-upper-v)
                                   ( 87 . evil-fringe-mark-upper-w)
                                   ( 88 . evil-fringe-mark-upper-x)
                                   ( 89 . evil-fringe-mark-upper-y)
                                   ( 90 . evil-fringe-mark-upper-z)
                                   ( 91 . evil-fringe-mark-symbol-lsquare)
                                   ( 93 . evil-fringe-mark-symbol-rsquare)
                                   ( 94 . evil-fringe-mark-symbol-caron)
                                   ( 97 . evil-fringe-mark-lower-a)
                                   ( 98 . evil-fringe-mark-lower-b)
                                   ( 99 . evil-fringe-mark-lower-c)
                                   (100 . evil-fringe-mark-lower-d)
                                   (101 . evil-fringe-mark-lower-e)
                                   (102 . evil-fringe-mark-lower-f)
                                   (103 . evil-fringe-mark-lower-g)
                                   (104 . evil-fringe-mark-lower-h)
                                   (105 . evil-fringe-mark-lower-i)
                                   (106 . evil-fringe-mark-lower-j)
                                   (107 . evil-fringe-mark-lower-k)
                                   (108 . evil-fringe-mark-lower-l)
                                   (109 . evil-fringe-mark-lower-m)
                                   (110 . evil-fringe-mark-lower-n)
                                   (111 . evil-fringe-mark-lower-o)
                                   (112 . evil-fringe-mark-lower-p)
                                   (113 . evil-fringe-mark-lower-q)
                                   (114 . evil-fringe-mark-lower-r)
                                   (115 . evil-fringe-mark-lower-s)
                                   (116 . evil-fringe-mark-lower-t)
                                   (117 . evil-fringe-mark-lower-u)
                                   (118 . evil-fringe-mark-lower-v)
                                   (119 . evil-fringe-mark-lower-w)
                                   (120 . evil-fringe-mark-lower-x)
                                   (121 . evil-fringe-mark-lower-y)
                                   (122 . evil-fringe-mark-lower-z)
                                   (123 . evil-fringe-mark-symbol-lcurly)
                                   (125 . evil-fringe-mark-symbol-rcurly)
                                   (128 . evil-fringe-mark-symbol-gtlt)
                                   (129 . evil-fringe-mark-symbol-lrsquare))
  "Alist of fringe bitmaps to display for characters.")

(provide 'evil-fringe-mark-overlays)
;;; evil-fringe-mark-overlays.el ends here
