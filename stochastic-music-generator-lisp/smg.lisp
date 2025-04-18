;;; STOCHASTIC MUSIC GENERATOR

;;; Yet Another AI-Inspired Markov Chain Music Generator in SBCL

;;; This program simulates early AI experiments by generating music using
;;; a Markov chain. Transition probabilities are defined for a diatonic major scale.
;;; Given a current note, the following one is chosen based on weighted probabilities.
;;; This tries to echo early work on algorithmic composition and rule-based systems.

;;; Basic functionality, rules, and settings:

;;; Diatonic Scale:      The notes list defines the available pitches of a C major scale.

;;; Markov Transitions:  The transitions table defines weighted probabilities
;;;                      for moving from one note to the next.

;;; Weighted Selection:  The "weighted-choice" function takes care that each note transition
;;;                      follows the defined probabilities.

;;; Melody Generation:   Starting from a specified note, the "generate-melody" function applies
;;;                      the Markov chain via the "next-note" function.

;;; To play around, change the transition weights, or add more notes (or even rules!). 


;; Define the C major scale, one octave
(defparameter *notes* '("C" "D" "E" "F" "G" "A" "B"))

;; Transition probabilities for each note (next-note . weight).
(defparameter *transitions*
  '(
    ("C" . (("D" . 0.3) ("E" . 0.3) ("G" . 0.4)))
    ("D" . (("E" . 0.4) ("F" . 0.3) ("C" . 0.3)))
    ("E" . (("F" . 0.4) ("G" . 0.3) ("D" . 0.3)))
    ("F" . (("G" . 0.5) ("A" . 0.2) ("E" . 0.3)))
    ("G" . (("A" . 0.3) ("B" . 0.3) ("C" . 0.4)))
    ("A" . (("B" . 0.4) ("C" . 0.3) ("F" . 0.3)))
    ("B" . (("C" . 0.5) ("D" . 0.5)))
    )
)


(defun weighted-choice (choices)
  "Selects an element from a (choice . weight) list as defined above.
  The function calculates the sum of weights, picks a random number within the total range,
  and returns the corresponding choice."
  (let ((total (reduce #'+ (mapcar #'cdr choices))))
    (let ((r (random total)))
      (loop for (choice . weight) in choices
            do (if (<= r weight)
                   (return choice)
                   (setf r (- r weight)))))))


(defun next-note (current-note)
  "Given a CURRENT-NOTE, this function chooses the next one based on the defined probabilities.
  If no transition exists (which actually shouldn't occur in the table defined above),
  a random note is chosen instead as a (hopefully unnecessary) precaution."
  (let ((transitions-for-note (cdr (assoc current-note *transitions* :test #'string=))))
    (if transitions-for-note
        (weighted-choice transitions-for-note)
        (nth (random (length *notes*)) *notes*))))


(defun generate-melody (length &optional (start "C"))
  "This high-level function generates a melody of a given length starting from a starting point."
  (let ((melody (list start)))
    (dotimes (i (1- length) melody)
      (push (next-note (car melody)) melody))
    (nreverse melody)))


(defun print-melody (melody)
  "Prints the melody to the console."
  (format t "Generated Melody: ~{~a ~}~%" melody))


(print-melody (generate-melody 32))