(require 'abbrev)

;; https://youtu.be/ruPpRlh2re4?t=110


(defset japanese-words
  "
1. 行く (iku) : go
2. 見る (miru) : see, look at
3. 多い (ooi) : a lot of, many
4. 家 (ie) : home, household
5. これ (kore) : this, this one
6. それ (sore) : that, that one
7. 私 (watashi) : I
8. 仕事 (shigoto) : work, job
9. いつ (itsu) : when
10. する (suru) : do, make
11. 出る (deru) : go out, leave
12. 使う (tsukau) : use, make use of
13. 所 (tokoro) : place
14. 作る (tsukuru) : make, create
15. 思う (omou) : think
16. 持つ (motsu) : have, possess
17. 買う (kau) : buy
18. 時間 (jikan) : time, hour
19. 知る (shiru) : know
20. 同じ (onaji) : same, identical
21. 今 (ima) : now
22. 新しい (atarashii) : new
23. なる (naru) : become
24. まだ (mada) : (not) yet, still
25. あと (ato) : after
26. 聞く (kiku) : hear, ask
27. 言う (iu) : say, tell
28. 少ない (sukunai) : few, little
29. 高い (takai) : high, tall
30. 子供 (kodomo) : child
31. そう (sou) : so, that way
32. もう (mou) : already, yet
33. 学生 (gakusei) : student
34. 熱い (atsui) : hot (to touch)
35. どうぞ (douzo) : please
36. 午後 (gogo) : afternoon, p.m.
37. 長い (nagai) : long
38. 本 (hon) : book, volume
39. 今年 (kotoshi) : this year (colloquial)
40. よく (yoku) : often, well
41. 彼女 (kanojo) : she, one’s girlfriend
42. どう (dou) : how, what
43. 言葉 (kotoba) : word, language
44. 顔 (kao) : face
45. 終わる (owaru) : finish, end
46. 一つ (hitotsu) : one (thing)
47. あげる (ageru) : give, offer (colloquial)
48. こう (kou) : like this, such
49. 学校 (gakkou) : school
50. くれる (kureru) : be given
51. 始める (hajimeru) : start (something)
52. 起きる (okiru) : get up, get out of bed
53. 春 (haru) : spring
54. 午前 (gozen) : morning, a.m.
55. 別 (betsu) : another, different
56. どこ (doko) : where
57. 部屋 (heya) : room
58. 若い (wakai) : young
59. 車 (kuruma) : car, automobile
60. 置く (oku) : put, place
")

(defun pen-abbrev-define-japanese ()
  (interactive)
  (let ((abbrevs
         (loop for line in
               (-filter-not-empty-string (str2lines japanese-words))
               collect
               (let ((tp
                      (s-split " " line)))
                 (list (s-replace-regexp
                        "(\\(.*\\))"
                        "\\1"
                        (third tp))
                       (second tp))))))

    (loop for ab in abbrevs
          do
          (define-abbrev global-abbrev-table
            (first ab)
            (second ab)))))

(pen-abbrev-define-japanese)

(provide 'pen-abbrev)
