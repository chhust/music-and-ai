import json
import os
import random

from markov_constants import *


class MarkovMusicGenerator:
    def __init__(self, adjacency_file):
        self.adjacency_matrices = self.load_adjacency_matrices(adjacency_file)              # load data from file
        self.adjacency_matrix   = None                                                      # store user choice here
        self.matrix_name        = None                                                      # store user choice here
        self.melody             = []                                                        # list for generated tones
        
        self.log_file           = LOGFILE
        self.log_data           = []


    def load_adjacency_matrices(self, file_path):
        """
        Load the contents of the adjacency matrices from file.
        """

        try:
            with open(file_path, 'r') as adjacency_file:
                data = json.load(adjacency_file)        # this includes a "__meta__" key that has to be filtered out
                return {key: value for key, value in data.items() if not key.startswith("__")}

        except FileNotFoundError:
            print(f"Could not find file '{file_path}'. Program terminated.")
            exit(0)


    def set_adjacency_matrix(self, descriptor=None):
        """
        This usually just calls "self.choose_adjacency_matrix" for manual selection
        unless a "descriptor" has been explicitly specified.
        """

        if descriptor:
            if descriptor in self.adjacency_matrices:
                self.matrix_name      = descriptor
                self.adjacency_matrix = self.adjacency_matrices[descriptor]
                return self.adjacency_matrix, self.matrix_name
            else:
                print(f"Descriptor '{descriptor}' not found. Proceeding to manual selection.")
                return self.choose_adjacency_matrix()

        else:
            return self.choose_adjacency_matrix()


    def choose_adjacency_matrix(self):
        """
        Automatically generates a main menu from the contents of the adjacency matrix file.
        """

        descriptors = list(self.adjacency_matrices.keys())                              # get the list of descriptors
        print("Available adjacency matrices\n")
        for number, string in enumerate(self.adjacency_matrices.keys(), start=1):       # descriptors are dict keys
            print(f"\t{number}. {string.title()}")

        choice = input("\nWhich matrix do you want to use ('r' for a random choice): ").strip()

        if choice.lower() == "q":
            return False

        elif choice.lower() == "r":
            self.matrix_name = random.choice(descriptors)                               # returns random selection

        else:
            try:
                index = int(choice) - 1
                if 0 <= index < len(descriptors):
                    self.matrix_name = descriptors[index]
                else:
                    print("Invalid choice. Selecting a randomly chosen matrix instead.")
                    self.matrix_name = random.choice(descriptors)

            except ValueError:
                print("Invalid input. Selecting a randomly chosen matrix.")
                self.matrix_name = random.choice(descriptors)

        self.adjacency_matrix = self.adjacency_matrices[self.matrix_name]

        return True


    def generate_melody(self):
        """
        This is the algorithm for melody generation. Check the (overly) detailed commentary in the code for more info.
        """

        melody_length = INITIAL_PROGRESSION_LENGTH

        # An alternative approach to the next two lines would be: current_note = TONIC_NOTE
        diatonic_notes   = [0, 2, 4, 5, 7, 9, 11]                       # always start with on a diatonic tones, ...
        current_note     = random.choice(diatonic_notes)                # ... and pick that randomly
        melody           = [current_note]                               # store as first note
        overflow_counter = 0                                            # initialize the overflow counter

        for _ in range(1, melody_length):                               # generate up to melody_length
            current_note = self.get_next_note(current_note)
            melody.append(current_note)

        # Now, ensure that the melody ends on the TONIC_NOTE:
        # First, try to reach this note organically in MAX_EXTENSION attempts.
        # If this fails, force it and end the generation process.
        # A more elegant way would be to brute-force TONIC_NOTE only if the probability from the current note is not 0.
        while melody[-1] != TONIC_NOTE:                                 # generate up to MAX_EXTENSION
            if overflow_counter >= MAX_EXTENSION:
                melody.append(TONIC_NOTE)                               # force tonic if MAX_EXTENSION has passed
                break

            current_note = self.get_next_note(current_note)
            melody.append(current_note)
            overflow_counter += 1

        self.log_data.append({                                          # prepare and save documentation
            "primary_voice"   : melody,
            "matrix_name"     : self.matrix_name,
            "overflow_counter": overflow_counter
        })
        self.save_log()

        return melody


    def get_next_note(self, current_note):
        """
        Determines the next note in the melody based on the current note and the Markov chain.

        Variables inside the loop:
        - "probability_sum" constructs a sequence of virtual 'boxes' with different sizes (according to the
           adjacency matrix, so the sizes are proportional to the occurrence probability of the notes in the matrix).
        - "random_number" simulates a 'ball' that is randomly thrown towards these boxes and lands in one of them.
        - "current_note" and "next_note" keep track of the current status of processing.
        """

        valid_diatonic_notes = [0, 2, 4, 5, 7, 9, 11]


        # First, calculate the sum of probabilities for the row of the current note:
        # This is the set of boxes (see above).

        probability_sum = sum(self.adjacency_matrix[current_note])

        if probability_sum == 0:
            next_note = random.choice(valid_diatonic_notes)
            self.log_data.append({
                "current_note"   : current_note,
                "next_note"      : next_note,
                "probability_sum": probability_sum,
                "random_number"  : None,
                "running_sum"    : None,
            })

            return next_note


        # Second, generate a random number and initialize variable for search process:
        # This is where the virtual 'ball' lands (see above).

        random_number = random.randint(0, probability_sum - 1)
        next_note, running_sum = 0, 0


        # Third, select "next_note" based on the transition probabilities from the adjacency matrix:
        # Subtract transition probability for current_note -> next_note from random_number,
        # increment next_note; do this until random_number < transition probability for current_note -> next_note.
        # Zero-values do not change random_number (-= 0), but increment next_note, effectively skipping them.
        # The code goes through the boxes until it finds the one in which the ball has landed (see above).

        while running_sum <= random_number:
            running_sum += self.adjacency_matrix[current_note][next_note]
            next_note += 1

        next_note -= 1

        if next_note >= PITCH_CLASSES:                                                      # just a safety precaution
            return random.choice(valid_diatonic_notes)

        self.log_data.append({
            "current_note"   : current_note,
            "next_note"      : next_note,
            "probability_sum": probability_sum,
            "random_number"  : random_number,
            "running_sum"    : running_sum,
        })

        return next_note


    def save_log(self):
        """
        Save log data to a file.
        """

        if not self.log_data:                                   # nothing to do (just a precaution measure)
            print("No data collected.")

            return

        if os.path.exists(self.log_file):                       # back up existing file
            base_name, _ = os.path.splitext(self.log_file)
            bak_name = f"{base_name}.bak"
            if os.path.exists(bak_name):
                os.remove(bak_name)

            os.rename(self.log_file, bak_name)

        with open(self.log_file, "w") as file:                  # save
            json.dump(self.log_data, file, indent=4)