;; e:/volumes/home/shane/notes/ws/problog/scratch/earthquake.problog

;; Things of this as just generating the prolog/problog
;; It should be able to generate both prolog and problog

;; I want it to be lispy through-and-through.
;; It simply generates the problog.

(require 'pen-epl)

;; A progn
(defun problog-model-burglary ()
  (interactive)

  (problog-play
   ;; e:/volumes/home/shane/notes/ws/problog/scratch/earthquake.problog

   ;; An optional annotation
   ;; Are problog annotations optional?
   (comment
    (pfacts ((burglary) 0.7)
            ((earthquake) 0.2)
            ((p_alarm1) 0.9)
            ((p_alarm2) 0.8)
            ((p_alarm4) 0.3)))

   (pfacts (burglary 0.7)
           (earthquake 0.2)
           (p_alarm1 0.9)
           (p_alarm2 0.8)
           (p_alarm4 0.3))

   ;; DISCARD Because I wouldn't be able to mix normal facts with annotated
   (comment
    (facts (burglary) 0.7
           (earthquake) 0.2
           (p_alarm1) 0.9
           (+p_alarm2) 0.8
           (not (p_alarm4 A B)) 1.0
           (not p_alarm5 A B) 0.3))

   ;; DONE Get these going
   (comment
    (pfacts ((burglary A B) 0.7)
            ((earthquake A B) 0.2)
            ((+p_alarm1 A B) 0.9)
            ;; DONE this also works
            ((not (p_alarm2 A B)) 0.8)
            (((not p_alarm2) A B) 0.8)
            ((not p_alarm4 A B) 0.3)))

   (comment
    ;; This is correct
    (fact (p_alarm3) 0.1)

    ;; This is correct
    (fact (flap_position 0 6))
    (fact flap_position 0 6)
    ;; This is correct
    ;; (fact flap_position 0 6)

    ;; This is incorrect
    (fact p_alarm3 0.1)

    ;; This is correct
    (fact p_alarm3 A B)
    ;; This is correct
    (fact "p_alarm3(A B)")
    ;; This is incorrect
    (fact (p_alarm3 A B) 0.1))

   ;; This is correct
   (pfact p_alarm3 0.1)

   ;; DONE *sigh* just use 'afact instead of 'pfact
   ;; I do want documentation
   (comment
    ;; This is also correct
    (afact 0.1 p_alarm3)
    ;; These are also correct
    (afact 0.1 p_alarm3 A B)
    (afact 0.1 +p_alarm3 A B)
    (afact 0.1 not p_alarm3 A B)
    (afact 0.1 (not p_alarm3 A B))
    (afact 0.1 (not p_alarm3) A B))

   (rules alarm
          (burglary earthquake p_alarm1)
          (burglary +earthquake p_alarm2)
          (burglary +earthquake p_alarm4))

   ;; DONE This method of inversing facts should work
   ;; taken care of in j:problog-function-sexp-to-string
   (comment
    (rules alarm
           (burglary earthquake p_alarm1)
           (burglary (not earthquake) p_alarm2)
           (burglary (not earthquake) p_alarm4)))

   (rule alarm +burglary earthquake p_alarm3)

   ;; DONE This method of inversing facts should work
   (comment
    (rule alarm (not burglary) earthquake p_alarm3))

   (evidence alarm t)

   ;; (evidence (alarm nil))

   (query burglary)
   (query earthquake)))

(defun problog-model-actuators ()
  (interactive)

  (problog-display
   ;; e:/volumes/home/shane/notes/ws/problog/scratch/aircraft-flap-controller.problog

   (%% "the range of the flap")
   ;; (rule "legal_flap_position(FP)" "between(0,10,FP)")
   ;; (rule "legal_flap_position FP" "between 0 10 FP")
   (rule (legal_flap_position FP) (between 0 10 FP))

   ;; DONE This is the same as above, but implemented a little differently
   (comment
    (implies (fact (legal_flap_position FP)) (fact (between 0 10 FP)))
    (implies (fact (+legal_flap_position FP)) (fact (between 0 10 FP)))
    (implies (fact (+legal_flap_position FP)) (fact (between 0 10 FP)))
    (implies (fact ((not legal_flap_position) FP)) (fact (between 0 10 FP)))
    (implies (fact ((not legal_flap_position) FP)) (fact ((not between) 0 10 FP)))
    (implies (fact (not legal_flap_position FP)) (fact (not between 0 10 FP))))

   (%% "the strength of the actuators")
   ;; (fact "actuator_strength(a,2)")
   (pfact (actuator_strength a 2))
   (pfact (actuator_strength b 1))

   (%% "random prior on which actuator to use")
   ;; "0.5::use_actuator(T,a); 0.5::use_actuator(T,b)."
   (or
    (pfact (use_actuator T a) 0.5)
    (pfact (use_actuantor T b) 0.5))

   (%% "wind strength model")
   ;; 0.7::wind(weak); 0.3::wind(strong).
   (or
    (pfact (wind weak) 0.7)
    (pfact (wind strong) 0.3))

   ;; 0.25::wind_effect(T,-1); 0.5::wind_effect(T,0); 0.25::wind_effect(T,1) :- wind(weak).
   (comment
    (implies
     (and
      (or
       (pfact (wind_effect T -1) 0.25)
       (pfact (wind_effect T 0) 0.5))
      (pfact (wind_effect T 1) 0.25))
     (fact (wind weak))))

   ;; "0.25::wind_effect(T,-1); 0.5::wind_effect(T,0); 0.25::wind_effect(T,1) :- wind(weak)."
   (implies
    (or
     (pfact (wind_effect T -1) 0.25)
     (pfact (wind_effect T 0) 0.5)
     (pfact (wind_effect T 1) 0.25))
    (fact (wind weak)))

   ;; 0.2::wind_effect(T,-3); 0.3::wind_effect(T,-2); 0.3::wind_effect(T,2); 0.2::wind_effect(T,3) :- wind(strong).
   (implies
    (or
     (pfact (wind_effect T -3) 0.2)
     (pfact (wind_effect T -2) 0.3)
     (pfact (wind_effect T 2) 0.3)
     (pfact (wind_effect T 3) 0.2))
    (fact (wind strong)))

   (%% the flap is moved to an attempted position if that is legal)
   ;; flap_position(Time,Pos) :- Time > 0, attempted_flap_position(Time,Pos), legal_flap_position(Pos).
   ;; TODO Model this also as an implies
   ;; (implies)
   (rule (flap_position Time Pos)
         (> Time 0)
         (attempted_flap_position Time Pos)
         (legal_flap_position Pos))

   (rule (overrun_exception Time)
         (attempted_flap_position Time Pos)
         ((not legal_flap_position) Pos))

   (rule (overrun_exception Time)
         (attempted_flap_position Time Pos)
         (not legal_flap_position Pos))

   (rule (goal_reached Time)
         (goal G)
         (flap_position Time G))

   (comment
    ;; An optional annotation
    ;; Are problog annotations optional?
    (pfacts (burglary 0.7)
            (earthquake 0.2)
            (p_alarm1 0.9)
            (p_alarm2 0.8))

    (rules alarm
           (burglary earthquake p_alarm1)
           (burglary +earthquake p_alarm2)))

   ;; attempted_flap_position(Time,Pos) :-
   ;;   Time > 0,
   ;;   Prev is Time-1,
   ;;   flap_position(Prev,Old),
   ;;   \+ goal(Old),
   ;;   use_actuator(Time,A),
   ;;   actuator_strength(A,AS),
   ;;   goal(GP),
   ;;   AE is sign(GP-Old)*AS,
   ;;   wind_effect(Time,WE),
   ;;   Pos is Old + AE + WE.

   (comment
    (rule (attempted_flap_position Time Pos) (is Prev (verbatim "Time-1")))
    (rule (attempted_flap_position Time Pos) (is Prev "Time-1")))

   (comment
    (is Prev (verbatim "Time-1")))
   (comment
    (is AE (verbatim "sign(GP-Old)*AS")))
   (comment
    (is Pos (verbatim "Old + AE + WE")))
   
   (rule (attempted_flap_position Time Pos)
         (> Time 0)
         
         (is Prev "Time-1")
         (flap_position Prev Old)
         (not goal Old)
         (use_actuator Time A)
         (actuator_strength A AS)
         (goal GP)
         
         (is AE "sign(GP-Old)*AS")
         (wind_effect Time WE)
         
         (is Pos "Old + AE + WE"))

   (%% "we want to go from 6 to 4, i.e., move two steps left")
   (comment
    (fact (flap_position 0 6)))
   (fact flap_position 0 6)

   (goal 4)

   (%% "restrict attention to first five steps")
   (at 5)

   (comment
    (evidence alarm t))

   ;; (evidence (alarm nil))

   (implies
    (query goal_reached T)
    (and
     (fact at S)
     (fact between 1 S T)))
   (implies
    (query overrun_exception T)
    (and
     (fact at S)
     (fact between 1 S T)))))

(provide 'pen-epl-test)