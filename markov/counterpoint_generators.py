import random

from markov_constants import *


class CounterpointGenerator:
    """
    This class comprises some methods for generating secondary voices.
    In all cases, calling the "counterpoint" is a rather big word for a rather small result. :)
    """


    def __init__(self, melody, adjacency_matrix):
        """
        Get everything defined.
        """

        self.melody = melody
        self.adjacency_matrix = adjacency_matrix
        self.counterpoint = []


    def generate_counterpoint_1(self):
        """
        This generator will always create a major third above the primary note.
        Tones are wrapped around the octave.
        """

        self.counterpoint = [(note + 4) % 12 for note in self.melody]
        return self.counterpoint


    def generate_counterpoint_2(self):
        """
        This generator will always create a diatonic third below the primary note.
        Tones are wrapped around the octave.
        The actual calculation is done in a helper function, see below.
        """

        self.counterpoint = [self.diatonic_third_below(note) for note in self.melody]
        return self.counterpoint


    def diatonic_third_below(self, primary):
        """
        For finding diatonic thirds, I manually define a diatonic pattern.
        Diatonic thirds can be either three or four pitch classes away from the primary tone, depending on the context.
        This is slightly more complex than the first method.
        """

        if primary == TONIC_NOTE:                           # cap at TONIC_NOTE to achieve tonal centricity
            return TONIC_NOTE

        # Pattern for C major: C      -,    D,     -,    E,    F,     -,    G,     -,    A,     -,    B
        diatonic_pattern = [True, False, True, False, True, True, False, True, False, True, False, True]
        secondary = primary

        # The inner while loop decrements the pitch class until it finds the next diatonic tone.
        # This is done twice, resulting in a third interval. For example, with E (pc 4) as primary note:
        # for loop, step 1: E (4) -> d# (3) -> D (2),
        # for loop, step 2: D (2) -> c# (1) -> C (0).
        for step in range(2):                               # find the second valid transition below the primary note
            while True:
                secondary = (secondary - 1 + PITCH_CLASSES) % PITCH_CLASSES     # wrap around if necessary
                if diatonic_pattern[secondary]:
                    break

        return secondary


    def generate_counterpoint_3(self):
        """
        This generator will pick a random diatonic note for each note in the primary voice.
        """

        self.counterpoint = [random.choice([0, 2, 4, 5, 7, 9, 11]) for _ in self.melody]
        return self.counterpoint


    def generate_counterpoint_4(self):
        """
        This generator will pick a random octatonic note for each note in the primary voice.
        """

        self.counterpoint = [random.choice([0, 1, 3, 4, 6, 7, 9, 10]) for _ in self.melody]
        return self.counterpoint


    def generate_counterpoint_5(self):
        """
        This generator will pick a random chromatic note for each note in the primary voice.
        """

        self.counterpoint = [random.choice(range(12)) for _ in self.melody]
        return self.counterpoint


    def generate_counterpoint_6(self):
        """
        This introduces at least some basic principles of music theory.
        It only makes sense using it with diatonic primary voices.
        """

        self.counterpoint = []
        prev_cp = None                              # track last generated tone

        for index, note in enumerate(self.melody):
            # First, create a list of consonant intervals to the primary voice tone
            #        (thus filtering the twelve chromatic notes),
            # then, filter out tones that would result in parallel fifths or octaves from this list.
            possible_notes = [note + interval for interval in range(12) if self.is_consonant(interval)]
            if prev_cp is not None:
                possible_notes = [n for n in possible_notes
                                  if not self.is_parallel_fifth_or_octave(self.melody[index-1], prev_cp, note, n)]

            if possible_notes:                                  # hopefully, there's something left!
                cp_note = random.choice(possible_notes) % 12    # or, "cp_note = possible_notes[0] % 12"
                self.counterpoint.append(cp_note)
                prev_cp = cp_note

            else:                                               # this should never happen, just another precaution
                cp_note = note
                self.counterpoint.append(cp_note)
                prev_cp = cp_note

        return self.counterpoint


    def is_consonant(self, interval):
        """
        Check if the interval is consonant:
        0 = unison; 3, 4 = minor, major third; 7 = perfect fifth; 8, 9 = minor, major sixth.
        """

        return interval in {0, 3, 4, 7, 8, 9}


    def is_parallel_fifth_or_octave(self, previous_primary, previous_secondary, current_primary, current_secondary):
        """
        Checks for parallel fifths or parallel octaves.
        """

        previous_interval = (previous_secondary - previous_primary) % 12
        current_interval  = (current_secondary  - current_primary)  % 12

        # Parallels are defined as two consecutive identical intervals, in this case octaves/unisons and perfect fifths
        return (previous_interval in {7, 0} and current_interval == previous_interval)


    def generate_counterpoint(self, choice):
        """
        The function names are stored in a dictionary. I always wanted to try that out! :)
        """

        methods = {
            1: self.generate_counterpoint_1,
            2: self.generate_counterpoint_2,
            3: self.generate_counterpoint_3,
            4: self.generate_counterpoint_4,
            5: self.generate_counterpoint_5,
            6: self.generate_counterpoint_6,
        }

        method = methods.get(choice)
        return method() if method else None


    def choose_counterpoint_method(self):
        """
        Menu and management of user input.
        """

        print("Choose a secondary voice generation method:")
        print("\t1. Major Thirds Above")
        print("\t2. Diatonic Thirds Below")
        print("\t3. Random Diatonic Notes")
        print("\t4. Random Octatonic Notes")
        print("\t5. Random Chromatic Notes")
        print("\t6. Rule-Based (super buggy!)")
        print("The further down the list, the less tested; expect some code crashes and nonsense results!")
        choice = input("\nEnter the number of your choice: ").strip()

        try:
            choice = int(choice)
        except ValueError:
            print("Value error.")
            return None

        return self.generate_counterpoint(choice)
