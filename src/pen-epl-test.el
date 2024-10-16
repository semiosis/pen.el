;; e:/volumes/home/shane/notes/ws/problog/scratch/earthquake.problog

;; Things of this as just generating the prolog/problog
;; It should be able to generate both prolog and problog

;; I want it to be lispy through-and-through.
;; It simply generates the problog.

(require 'pen-epl)

(defun problog-basic-coin ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/basic-coin.problog

We are interested in both coins landing on heads"

  (interactive)
  
  (problog-play-or-display
   ;; the first coin flip has a 0.5 probability of being heads
   ;; the second coin flip has a 0.5 probability of being heads
   (pfacts (heads1 0.5)
           (heads2 0.6))

   ;; twoHeads is true if both flips are heads
   (rule twoHeads heads1 heads2)
   
   (query heads1)
   (query heads2)

   ;; The probability of both coins landing on heads is the product of both probabilities: P(twoHeads)=0.3.
   ;; This has a  low probability - 0.3
   (query twoHeads)))

(defun noisy-or-coin ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/noisy-or-coin.problog

Let’s now consider a variant of the above example j:problog-basic-coin in which we are interested not in both coins landing on heads, but in at least one of them landing on heads."

  (interactive)
  
  (problog-play-or-display
   (pfacts (heads1 0.5)
           (heads2 0.6))

   ;; twoHeads is true if both flips are heads
   (pfact heads1 0.5)
   (pfact heads1 0.5)

   (prules someHeads
          (heads1)
          (heads2))

   ;; This has a very high probability - 0.95
   (query someHeads)))

(defun first-order-coin ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/first-order-coin.problog

We toss N coins (which are all biased with probability 0.6 for heads)
and we are interested in the probability of at least one of them
landing on heads"

  (interactive)
  (problog-play-or-display
   ;; The chance of something (normally a coin) landing heads is 0.6
   ;; probabilistic fact    | 0.5::a.
   (afact 0.6 lands_heads _)

   ;; There are 4 coins
   (facts
    (coin c1)
    (coin c2)
    (coin c3)
    (coin c4))

   (implies
    ;; Something (C) must have landed heads
    (fact heads C)
    ;; if...
    ;; C is a coin, and
    ;; C lands heads (there's only a 60% chance of that)
    (pb-and (fact coin C)
            (fact lands_heads C)))
   
   (implies
    ;; There has been at least one heads
    (fact someHeads)
    ;; if heads is true for anything
    (fact heads _))

   (query someHeads)))

;; j:first-order-coin rewritten
(defun probabilistic-clause-coin ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/probabilistic-clause-coin.problog"
  (interactive)
  (problog-play-or-display

   ;; probabilistic clause  | 0.5::a :- x.
   ;; probabilistic clauses help to reduce auxiliary predicates
   (comment
    (implies (afact 0.6 heads C)
             (fact coin C)))

   (rule (heads C) 0.6 (coin C))

   ;; c1 to c4 are coins
   (facts
    (coin c1)
    (coin c2)
    (coin c3)
    (coin c4))

   ;; If there are some heads then one of the coins
   ;; i.e. _ landed as a head
   (implies (fact someHeads)
            (fact heads _))

   (query someHeads)))

(defun probabilistic-burglary ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/earthquake.problog

Bayesian networks in ProbLog using the famous Earthquake example.

In this example, we have a chance that a burglary has happened,
and a chance that an earthquake has happened,
and there is also sure evidence that the alarm has gone off.

There are some rules which say under what circumstances does the alarm trigger,
and those rules 
"

  (interactive)
  (problog-play-or-display

   (pfacts
    ;; Suppose there is a burglary in our house with probability 0.7
    ;; and an earthquake with probability 0.2.
    ;; In other words, there may be one or the other, both or neither.
    (burglary 0.7)
    (earthquake 0.2)

    ;; The probabilities for the conclusions of the
    ;; 3 different rules for what triggers the alarm.
    ;; While this is a correct encoding of the
    ;; given Bayesian network, it is perhaps not very
    ;; intuitive due to the auxiliary atoms, p_alarm1, p_alarm2 and p_alarm3
    (p_alarm1 0.9)
    (p_alarm2 0.8)
    (p_alarm3 0.1))

   ;; Here, the alarms all represent the same alarm. The alarm predicate is described
   ;; by 3 different rules. They are 3 different scenarios which could have triggered the alarm.
   ;; - if there is a burglary and an earthquake, the alarm rings with probability 0.9;
   ;; - if there is only a burglary, it rings with probability 0.8;
   ;; - if there is only an earthquake, it rings with probability 0.1;
   (prules alarm
           ;;  3 different rules for what triggers the alarm
           (burglary earthquake p_alarm1)
           (burglary +earthquake p_alarm2)
           (+burglary earthquake p_alarm3))

   ;; The query and evidence functions are for clauses.
   ;; It adjusts the probability to make it 100%
   ;; While you can use 'evidence' on a probabilistic fact, it's not that
   ;; useful to do so, because you could just set the probability right there.
   ;; But if you use 'evidence' on a rule which refers to auxiliary predicates and
   ;; facts that have their own probabilities, then you can adjust the original
   ;; probabilities, even if they were hardcoded.

   ;; Alarm is a predicate (a pure boolean function) but it's stochastic so
   ;; it's not technically pure (by haskell standards).
   ;; By giving evidence, we say that the final probability must be 100%.
   ;; The alarm has gone off
   (evidence alarm t)
   
   ;; (evidence p_alarm1 t)
   ;; There is no evidence for an alarm having gone off
   (comment (evidence alarm t))
   ;; The alarm has not gone off
   ;; (evidence alarm nil)

   ;; What was the chance of there being a burglary?
   (query burglary)

   ;; What was the chance of there being an earthquake?
   (query earthquake)

   ;; What was the likely underlying rule of the alarm predicate
   ;; which triggered the alarm?
   ;; By giving evidence, we say that the final probability must be 100%.
   (query p_alarm1)
   ;; The most likely scenario which triggered the alarm was a burglary
   ;; without an earthquake.
   (query p_alarm2)
   ;; p_alarm3 was only around 0.1 percent
   ;; therefore, it's very unlikely that it was an earthquake without
   ;; a burglary.
   (query p_alarm3)))

(defun probabilistic-burglary-using-pclauses ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/earthquake-probabilistic-clauses.problog"
  (interactive)
  (problog-play-or-display

   (pfacts
    ;; Suppose there is a burglary in our house with probability 0.7
    ;; and an earthquake with probability 0.2.
    ;; In other words, there may be one or the other, both or neither.
    (burglary 0.7)
    (earthquake 0.2))

   ;; Here, the alarms all represent the same alarm. The alarm predicate is described
   ;; by 3 different rules. They are 3 different scenarios which could have triggered the alarm.
   ;; - if there is a burglary and an earthquake, the alarm rings with probability 0.9;
   ;; - if there is only a burglary, it rings with probability 0.8;
   ;; - if there is only an earthquake, it rings with probability 0.1;
   (prules alarm
           ;;  3 different rules for what triggers the alarm
           (0.9 burglary earthquake)
           (0.8 burglary +earthquake)
           (0.1 +burglary earthquake))

   ;; The query and evidence functions are for clauses.
   ;; It adjusts the probability to make it 100%
   ;; While you can use 'evidence' on a probabilistic fact, it's not that
   ;; useful to do so, because you could just set the probability right there.
   ;; But if you use 'evidence' on a rule which refers to auxiliary predicates and
   ;; facts that have their own probabilities, then you can adjust the original
   ;; probabilities, even if they were hardcoded.

   ;; Alarm is a predicate (a pure boolean function) but it's stochastic so
   ;; it's not technically pure (by haskell standards).
   ;; By giving evidence, we say that the final probability must be 100%.
   ;; The alarm has gone off
   (evidence alarm t)
   
   ;; (evidence p_alarm1 t)
   ;; There is no evidence for an alarm having gone off
   (comment (evidence alarm t))
   ;; The alarm has not gone off
   ;; (evidence alarm nil)

   ;; What was the chance of there being a burglary?
   (query burglary)

   ;; What was the chance of there being an earthquake?
   (query earthquake)))

(defun probabilistic-burglary-using-firstorder-logic ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/earthquake-firstorder.problog"
  
  (interactive)
  (problog-play-or-display

   ;; There are 2 'person' defined.
   (facts
    (person john)
    (person mary))

   ;; I can also do this:
   (comment
    (pfacts
     ((person john))
     ((person mary))))

   (pfacts
    ;; Suppose there is a burglary in our house with probability 0.7
    ;; and an earthquake with probability 0.2.
    ;; In other words, there may be one or the other, both or neither.
    (burglary 0.7)
    (earthquake 0.2))

   ;; Here, the alarms all represent the same alarm. The alarm predicate is described
   ;; by 3 different rules. They are 3 different scenarios which could have triggered the alarm.
   ;; - if there is a burglary and an earthquake, the alarm rings with probability 0.9;
   ;; - if there is only a burglary, it rings with probability 0.8;
   ;; - if there is only an earthquake, it rings with probability 0.1;
   (prules alarm
           ;;  3 different rules for what triggers the alarm
           (0.9 burglary earthquake)
           (0.8 burglary +earthquake)
           (0.1 +burglary earthquake)
           ;; Sometimes it's a false-alarm:
           ;; i.e. no burglary or earthquake happened,
           ;; but the alarm still triggered
           ;; (0.01 +burglary +earthquake)
           )

   ;; There are N people. X represents one of those people.
   ;; Since we know there are only 2 'person' defined,
   ;; N=2.
   (prules (calls X)
           ;;  3 different rules for what triggers the alarm
           (0.9 alarm (person X))
           (0.8 +alarm (person X)))

   ;; The query and evidence functions are for clauses.
   ;; It adjusts the probability to make it 100%
   ;; While you can use 'evidence' on a probabilistic fact, it's not that
   ;; useful to do so, because you could just set the probability right there.
   ;; But if you use 'evidence' on a rule which refers to auxiliary predicates and
   ;; facts that have their own probabilities, then you can adjust the original
   ;; probabilities, even if they were hardcoded.

   ;; Alarm is a predicate (a pure boolean function) but it's stochastic so
   ;; it's not technically pure (by haskell standards).
   ;; By giving evidence, we say that the final probability must be 100%.
   ;; The alarm has gone off
   (evidence (calls john) t)
   (evidence (calls mary) t)
   
   ;; What was the chance of there being a burglary?
   (query burglary)

   ;; What was the chance of there being an earthquake?
   (query earthquake)))

(defun probabilistic-burglary-using-annotated-disjunctions ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/annotated-disjunctions-earthquake.problog

Since the random variables in the Bayesian
network are all Boolean, we only need a single
literal in the head of the rules.

We can extend the Bayesian network to have a
multi-valued variable by indicating the
severity of the earthquake.

The literal 'earthquake' now has three possible
values 'none', 'mild', 'heavy' instead of previously
two ('no' or 'yes').

The probabilities of each value is denoted by
the annotated disjunction in
    0.01::earthquake(heavy);
    0.19::earthquake(mild); 0.8::earthquake(none).

An annotated disjunction is similar to a
probabilistic disjunction, but with a
different head.

Instead of it being one atom annotated with a
probability, it is now a disjunction of atoms
each annotated with a probability."

  (interactive)
  (problog-play-or-display

   (facts
    (person john)
    (person mary))

   (pfacts
    ;; Suppose there is a burglary in our house with probability 0.7
    ;; and an earthquake with probability 0.2.
    (burglary 0.7))

   ;; We could express the same thing in an annotated disjunction:
   (comment
    (pb-or (afact 0.7 burglary)
           (afact 0.3 (not burglary))))

   ;; Fuzzy logic! / categories / multi-valued variable
   (pb-or (afact 0.01 earthquake heavy)
          (afact 0.19 earthquake mild)
          (afact 0.8 earthquake none))
   
   (comment (pb-or (pfact earthquake 0.01 heavy)
                   (pfact earthquake 0.19 mild)
                   (pfact earthquake 0.8 none)))

   ;; Here, the alarms all represent the same alarm. The alarm predicate is described
   ;; by 3 different rules. They are 3 different scenarios which could have triggered the alarm.
   ;; - if there is a burglary and an earthquake, the alarm rings with probability 0.9;
   ;; - if there is only a burglary, it rings with probability 0.8;
   ;; - if there is only an earthquake, it rings with probability 0.1;
   (prules alarm
           ;;  3 different rules for what triggers the alarm
           (0.90 burglary (earthquake heavy))
           (0.85 burglary (earthquake mild))
           (0.80 burglary (earthquake none))
           (0.10 +burglary (earthquake mild))
           (0.30 +burglary (earthquake heavy)))

   (prules (calls X)
           ;;  3 different rules for what triggers the alarm
           (0.9 alarm (person X))
           (0.8 +alarm (person X)))

   ;; The query and evidence functions are for clauses.
   ;; It adjusts the probability to make it 100%
   ;; While you can use 'evidence' on a probabilistic fact, it's not that
   ;; useful to do so, because you could just set the probability right there.
   ;; But if you use 'evidence' on a rule which refers to auxiliary predicates and
   ;; facts that have their own probabilities, then you can adjust the original
   ;; probabilities, even if they were hardcoded.

   ;; Alarm is a predicate (a pure boolean function) but it's stochastic so
   ;; it's not technically pure (by haskell standards).
   ;; By giving evidence, we say that the final probability must be 100%.
   ;; The alarm has gone off
   (evidence (calls john) t)
   (evidence (calls mary) t)

   ;; What was the chance of there being a burglary?
   (query burglary)

   ;; What was the chances of each type of earthquake including no earthquake?
   ;; Notice that this does NOT say, "What is the chance there was earthquake?"
   (query (earthquake _))))

(defun problog-rolling-dice-annotated-disjunctions ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/rolling-dice-with-annotated-disjunctions-ie-multi-valued-variables.problog

We start with a variant of our earlier
propositional coin example, but now using
dice.

It illustrates the use of annotated
disjunctions, a probabilistic primitive that
chooses exactly one of a number of
alternatives (if their probabilities sum to
1.0, if the sum is less than 1.0, then with
some probability none of the alternatives is
picked).

The first die is fair, the second has a higher
chance of throwing a six.

Furthermore, we define what it means to throw
a six with both dice, or with at least one of
them.
"
  (interactive)
  (problog-play-or-display

   (pb-or
    (afact 1/6 one1)
    (afact 1/6 two1)
    (afact 1/6 three1)
    (afact 1/6 four1)
    (afact 1/6 five1)
    (afact 1/6 six1))

   ;; The second die is weighted
   (pb-or (afact 0.15 one2)
          (afact 0.15 two2)
          (afact 0.15 three2)
          (afact 0.15 four2)
          (afact 0.15 five2)
          (afact 0.25 six2))

   (rules twoSix
          (six1 six2))
   (rules someSix
          (six1)
          (six2))

   ;; Make these work as expected
   (comment
    (rules twoSix
           (six1 OR six2))
    (rules twoSix
           ((pb-or six1 six2))))

   (query six1)
   (query six2)
   (query twoSix)
   (query someSix)))

(defun problog-rolling-dice-negation-as-failure ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/rolling-dice-negation-as-failure.problog

"
  (interactive)
  (problog-play-or-display

   (pb-or
    (afact 1/6 one 1)
    (afact 1/6 two 1)
    (afact 1/6 three 1)
    (afact 1/6 four 1)
    (afact 1/6 five 1)
    (afact 1/6 six 1))

   ;; The second die is weighted
   (pb-or (afact 0.15 one 2)
          (afact 0.15 two 2)
          (afact 0.15 three 2)
          (afact 0.15 four 2)
          (afact 0.15 five 2)
          (afact 0.25 six 2))

   (rules (odd X)
          ;;  3 different rules for what triggers the alarm
          ((one X))
          ((three X))
          ((five X)))
   
   (rules (even X)
          ((not (odd X))))

   (query (odd 1))
   (query (even 1))
   (query (odd 2))
   (query (even 2))))

(defun problog-rolling-dice-non-ground-queries ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/rolling-dice-non-ground-queries.problog

As in Prolog, negation has to be used with
care, as it is only safe on ground goals.

We illustrate this by posing non-ground
queries (using an anonymous variable denoted
by _ as argument) to the same program.
"
  (interactive)
  (problog-play-or-display

   (pb-or
    (afact 1/6 one 1)
    (afact 1/6 two 1)
    (afact 1/6 three 1)
    (afact 1/6 four 1)
    (afact 1/6 five 1)
    (afact 1/6 six 1))

   ;; The second die is weighted
   (pb-or (afact 0.15 one 2)
          (afact 0.15 two 2)
          (afact 0.15 three 2)
          (afact 0.15 four 2)
          (afact 0.15 five 2)
          (afact 0.25 six 2))

   (rules (odd X)
          ;;  3 different rules for what triggers the alarm
          ((one X))
          ((three X))
          ((five X)))
   
   (rules (even X)
          ((not (odd X))))

   ;; What was the chance of there being a burglary?
   (query (odd _))
   (query (even _))))

(defun problog-rolling-dice-arithmetic-expressions ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/rolling-dice-arithmetic-expressions.problog

We now consider yet another way to model dice,
using fair ones only.

This representation allows for convenient use
of the results in arithmetic expressions,
e.g., to add up the results from several dice.

We query for the probabilities of the possible
sums we can get from two dice given that the
first number is even and the second odd.
"
  (interactive)
  (problog-play-or-display

   (pb-or
    (afact 1/6 one 1)
    (afact 1/6 two 1)
    (afact 1/6 three 1)
    (afact 1/6 four 1)
    (afact 1/6 five 1)
    (afact 1/6 six 1))

   ;; The second die is weighted
   (pb-or (afact 0.15 one 2)
          (afact 0.15 two 2)
          (afact 0.15 three 2)
          (afact 0.15 four 2)
          (afact 0.15 five 2)
          (afact 0.25 six 2))

   (rules (odd X)
          ;;  3 different rules for what triggers the alarm
          ((one X))
          ((three X))
          ((five X)))
   
   (rules (even X)
          ((not (odd X))))

   ;; What was the chance of there being a burglary?
   (query (odd _))
   (query (even _))))

(defun problog-getting-wet ()
  "e:/volumes/home/shane/notes/ws/problog/scratch/getting-wet.problog

Calculate the probability of getting wet
given the probabilities for rain and the
probabilities that someone brings an umbrella:
"
  (interactive)
  (problog-play-or-display

   (afacts
    (0.4 rain weekday)
    (0.9 rain weekend)
    (0.8 umbrella_if_rainy Day)
    (0.2 umbrella_if_dry Day))

   (rules (umbrella Day)
          ;;  3 different rules for what triggers the alarm
          ((rain Day))
          ((not (umbrella Day))))

   (implies
    (fact (umbrella Day))
    (pb-or (fact rain Day)
           (fact umbrella_if_rainy Day)))

   ;; This should work
   (rule (umbrella Day)
         (or (not (rain Day))
             (umbrella_if_dry Day)))
   
   (rules (wet X)
          ((rain Day))
          (( Day)))

   ;; What was the chance of there being a burglary?
   (query (odd _))
   (query (even _))))

;; A progn
(defun problog-model-burglary-test ()
  (interactive)

  (problog-play-or-display
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
    ;; This pb-is correct
    (fact (p_alarm3) 0.1)

    ;; This pb-is correct
    (fact (flap_position 0 6))
    (fact flap_position 0 6)
    ;; This pb-is correct
    ;; (fact flap_position 0 6)

    ;; This pb-is incorrect
    (fact p_alarm3 0.1)

    ;; This pb-is correct
    (fact p_alarm3 A B)
    ;; This pb-is correct
    (fact "p_alarm3(A B)")
    ;; This pb-is incorrect
    (fact (p_alarm3 A B) 0.1))

   ;; This pb-is correct
   (pfact p_alarm3 0.1)

   ;; DONE *sigh* just use 'afact instead of 'pfact
   ;; I do want documentation
   (comment
    ;; This pb-is also correct
    (afact 0.1 p_alarm3)
    ;; These are also correct
    (afact 0.1 p_alarm3 A B)
    (afact 0.1 +p_alarm3 A B)
    (afact 0.1 not p_alarm3 A B)
    (afact 0.1 (not p_alarm3 A B))
    (afact 0.1 (not p_alarm3) A B))

   (prules alarm
          (burglary earthquake p_alarm1)
          (burglary +earthquake p_alarm2)
          (burglary +earthquake p_alarm4))

   ;; DONE This method of inversing facts should work
   ;; taken care of in j:problog-function-sexp-to-string
   (comment
    (prules alarm
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

   ;; DONE This pb-is the same as above, but implemented a little differently
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

   (%% the flap pb-is moved to an attempted position if that pb-is legal)
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

    (prules alarm
           (burglary earthquake p_alarm1)
           (burglary +earthquake p_alarm2)))

   ;; attempted_flap_position(Time,Pos) :-
   ;;   Time > 0,
   ;;   Prev pb-is Time-1,
   ;;   flap_position(Prev,Old),
   ;;   \+ goal(Old),
   ;;   use_actuator(Time,A),
   ;;   actuator_strength(A,AS),
   ;;   goal(GP),
   ;;   AE pb-is sign(GP-Old)*AS,
   ;;   wind_effect(Time,WE),
   ;;   Pos pb-is Old + AE + WE.

   (comment
    (rule (attempted_flap_position Time Pos) (pb-is Prev (verbatim "Time-1")))
    (rule (attempted_flap_position Time Pos) (pb-is Prev "Time-1")))

   (comment
    (pb-is Prev (verbatim "Time-1")))
   (comment
    (pb-is AE (verbatim "sign(GP-Old)*AS")))
   (comment
    (pb-is Pos (verbatim "Old + AE + WE")))
   
   (rule (attempted_flap_position Time Pos)
         (> Time 0)
         
         (pb-is Prev "Time-1")
         (flap_position Prev Old)
         (not goal Old)
         (use_actuator Time A)
         (actuator_strength A AS)
         (goal GP)
         
         (pb-is AE "sign(GP-Old)*AS")
         (wind_effect Time WE)
         
         (pb-is Pos "Old + AE + WE"))

   (%% "we want to go from 6 to 4, i.e., move two steps left")
   (comment
    (fact (flap_position 0 6)))
   (fact flap_position 0 6)

   (goal 4)

   (%% "restrict attention to first five steps")
   (pb-at 5)

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
