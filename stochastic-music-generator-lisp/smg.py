"""
This is a Python translation of the LISP code, purely for documentation.
"""

import random


NOTES = ["C", "D", "E", "F", "G", "A", "B"]

TRANSITIONS = {
    "C": [("D", 0.3), ("E", 0.3), ("G", 0.4)],
    "D": [("E", 0.4), ("F", 0.3), ("C", 0.3)],
    "E": [("F", 0.4), ("G", 0.3), ("D", 0.3)],
    "F": [("G", 0.5), ("A", 0.2), ("E", 0.3)],
    "G": [("A", 0.3), ("B", 0.3), ("C", 0.4)],
    "A": [("B", 0.4), ("C", 0.3), ("F", 0.3)],
    "B": [("C", 0.5), ("D", 0.5)],
}


def weighted_choice(choices):
    """
    Sums up all weights into a total, then generates a random number between 0 and the total.
    The choice algorithm is the "throw a ball in boxes" idea as explained in the second Markov code.

    (defun weighted-choice (choices)
        (let ((total (reduce #'+ (mapcar #'cdr choices))))
            (let ((r (random total)))
                (loop for (choice . weight) in choices
                    do (if (<= r weight)
                       (return choice)
                       (setf r (- r weight)))))))
    """

    total = sum(weight for _, weight in choices)

    r = random.random() * total

    for choice, weight in choices:
        if r <= weight:
            return choice
        r -= weight

    return None             # enforce an error message


def next_note(current_note):
    """
    Choose the next note: look up (next_note, weight) in the TRANSITIONS data.
    If it's in there, call weighted_choice.
    If not (which should not happen), picks a random note from NOTES. Just an unnecessary precaution.

    (defun next-note (current-note)
        (let ((transitions-for-note (cdr (assoc current-note *transitions* :test #'string=))))
            (if transitions-for-note
                (weighted-choice transitions-for-note)
                (nth (random (length *notes*)) *notes*))))
    """

    transitions_for_note = TRANSITIONS.get(current_note)

    if transitions_for_note:
        return weighted_choice(transitions_for_note)

    return random.choice(NOTES)


def generate_melody(length, start="C"):
    """
    This is basically the main function: initialize melody list, and iterate over it (from 1 to length):
    - check last element
    - calculate next note and append it to the list
    - return the melody list

    (defun generate-melody (length &optional (start "C"))
        (let ((melody (list start)))
            (dotimes (i (1- length) melody)
                (push (next-note (car melody)) melody))
            (nreverse melody)))
    """

    melody = [start]

    for _ in range(1, length):
        melody.append(next_note(melody[-1]))

    return melody


def print_melody(melody):
    """
    Output only. Trivial.

    (defun print-melody (melody)
        (format t "Generated Melody: ~{~a ~}~%" melody))
    """

    print("Generated Melody:", " ".join(melody))


print_melody(generate_melody(32))           # the argument is the melody length