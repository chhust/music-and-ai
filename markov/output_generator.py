"""
This class uses PyGame Mixer for audio output. There's an alternative version using sounddevice in OutputGenerator_old.py.
"""


import json
import os
import pygame
import time

import matplotlib.pyplot as plt

from markov_constants import *


class AudioOutputGenerator:
    def __init__(self, sample_path="samples"):
        """
        Init values.
        """

        self.sample_path = sample_path
        self.pitch_to_file = self._map_pitch_classes_to_samples()

        pygame.mixer.init()


    def _map_pitch_classes_to_samples(self):
        """
        Map pitch classes to sample files
        using the specific file names from https://github.com/parisjava/wav-piano-sound/tree/master/wav.
        """

        mapped_files = {}
        pitch_map = {
             0: "c1",   1: "c1s",
             2: "d1",   3: "d1s",
             4: "e1",
             5: "f1",  6: "f1s",
             7: "g1",  8: "g1s",
             9: "a1", 10: "a1s",
            11: "b1",
            12: "c2"                    # not actually used
        }

        for pitch_class, name in pitch_map.items():
            filename = f"wav_{name}.wav"
            full_path = os.path.join(self.sample_path, filename)
            if os.path.exists(full_path):
                mapped_files[pitch_class] = full_path
            else:
                print(f"Missing file for audio output: '{full_path}'!")
                exit(-1)

        return mapped_files


    def play_note(self, pitch_class):
        """
        Play a single note.
        """

        if pitch_class not in self.pitch_to_file:                   # should not happen as files were checked earlier
            print(f"No sample for pitch class '{pitch_class}'.")
            return

        pygame.mixer.Sound(self.pitch_to_file[pitch_class]).play()


    def play_melody(self, primary, secondary, note_duration=0.5):
        """
        Wrapper function: simultaneously plays the primary and secondary voices.
        """

        for note1, note2 in zip(primary, secondary):
            self.play_note(note1)
            self.play_note(note2)
            time.sleep(note_duration)


class TextOutputGenerator:
    """
    Text output generation.
    """

    def __init__(self, primary, secondary):
        """
        Init values.
        """

        self.primary   = primary
        self.secondary = secondary


    def display_output(self):
        """
        Format notes, then print them as a table.
        """

        formatted_primary   = self.format_notes(self.primary)
        formatted_secondary = self.format_notes(self.secondary)

        print("  Primary  | Secondary ")
        print("-----------+-----------")
        for index in range(len(self.primary)):
            print(f"  {formatted_primary[index]:<8} |  {formatted_secondary[index]:<9}")


    def format_notes(self, notes):
        """
        Convert pitch class to a format of [NOTE NAME] (pitch class number).
        """

        return [f"{PITCH_NAMES[note % 12]} ({note:02})" for note in notes]


class JSONOutputGenerator:
    """
    This class plays around with the LOGFILE info.
    """


    def __init__(self):
        """
        Init values.
        """

        self.log_file = LOGFILE
        self.log_data = self.load_log_data()


    def load_log_data(self):
        """
        Load data from file
        """

        try:
            with open(self.log_file, "r") as file:
                return json.load(file)

        except FileNotFoundError:
            print(f"Could not find {self.log_file}.")
            return None

        except json.JSONDecodeError:
            print(f"'{self.log_file}' is possibly not a JSON file.")
            return None


    def plot_melody(self, adjacency_matrix):
        """
        This method combines all graphical outputs into a single plot,
                    showing the melody, probability sums, random numbers, and the composition of probability sums.

        It is mostly a convoluted experiment with matplotlib,
        and writing it took me more time than I'm ever willing to admit.
        """

        # Prepare the data
        melody           = self.log_data[-1]["primary_voice"]
        probability_sums = [entry["probability_sum"] for entry in self.log_data if "probability_sum" in entry]
        random_numbers   = [entry["random_number"]   for entry in self.log_data if "random_number"   in entry]
        overflow_counter = self.log_data[-1]["overflow_counter"]

        # Varying lengths: having n steps means that there are only n-1 transitions
        steps_melody      = range(len(melody))
        steps_transitions = range(len(probability_sums))

        # Normalize dice rolls to match the probability sum scale
        try:
            normalized_random_numbers = [rn / max(probability_sums[i], 1) * 12 for i, rn in enumerate(random_numbers)]
        except:
            normalized_random_numbers = []

        # Initialize output area with two subplots
        figure, (markov_plot, probability_plot) = plt.subplots(2, 1, figsize=(14, 10))

        # FIRST SUBPLOT: Plot the primary voice (Markov-generated)
        markov_plot.plot(steps_melody, melody, marker="X", label="Markov Voice", color="blue")

        # Iterate and annotate: (no text, end point = next tone, starting point = current tone, black arrow, slightly smaller)
        #                        Admittedly, this is just for show.
        for index in range(len(melody) - 1):
            markov_plot.annotate("", xy=(index+1, melody[index+1]), xytext=(index, melody[index]),
                                 arrowprops={"facecolor": "black", "shrink": .05})

        # Mark the beginning of the overflow area
        if overflow_counter > 0:
            markov_plot.axvline(x=len(melody) - overflow_counter - 1, color="red",
                                linestyle="--", label="Overflow Start")

        # Add horizontal lines for each pitch class
        for pitch in range(12):
            markov_plot.axhline(y=pitch, color="gray", linestyle=":", linewidth=.5)

        # Add legend
        markov_plot.set_xlabel("Note Position")
        markov_plot.set_ylabel("Pitch Class")
        markov_plot.set_title("Primary Voice (Markov-Generated)")
        markov_plot.legend()

        # SECOND, plot the normalized random numbers and stacked probabilities.
        #         They will always precede the melody lines by one step because they determine the next note.
        probability_plot.plot(steps_transitions, normalized_random_numbers, marker=".", linestyle="-", color="green",
                              label="Normalized Dice Roll")
        
        bottom = [0] * len(steps_transitions)   # bottom is a list determining where the next stacks will rise from
        num_notes = len(adjacency_matrix[0])    # number of possible next notes: usually 12
        all_probabilities = []                  # prepare a list
        
        # Collect the relevant data from the adjacency matrix
        for entry in self.log_data[:-1]:                            # [:-1] -- skip the last entry in log data
            current_note  = entry["current_note"]                   # get current note
            probabilities = adjacency_matrix[current_note]          # get corresponding row in the matrix, ...
            total = sum(probabilities)                              # ..., get the sum, ...
            if total != 0:                                          # ..., normalize to 12, ...
                probabilities = [p / total * 12 for p in probabilities]
            all_probabilities.append(probabilities)                 # ..., and append it to the list.

        # Account for the different length of tones and transitions
        if len(all_probabilities) < len(steps_transitions):
            if len(melody) > 1:
                last_probabilities = adjacency_matrix[melody[-2]]
            else:
                last_probabilities = adjacency_matrix[melody[0]]    # should never happen, just another precaution
            total = sum(last_probabilities)
            if total != 0:
                last_probabilities = [probs / total * 12 for probs in last_probabilities]
            all_probabilities.append(last_probabilities)

        # Calculate and plot the stacked bars
        for index in range(num_notes):                              # iterate all notes and plot from left to right
            heights = [probs[index] for probs in all_probabilities] # heights for the nth note's transition probability
            probability_plot.bar(steps_transitions, heights, bottom=bottom,
                                 label=f"{PITCH_NAMES[index]}", alpha=.6) # 60 % transparency
            bottom = [sum(x) for x in zip(bottom, heights)]         # update bottom for stacking

        # Prepare second legend
        probability_plot.set_xlabel("Transition Steps")
        probability_plot.set_ylabel("Probabilities and Dice Rolls")
        probability_plot.set_title("Transition Probabilities and Dice Rolls")
        probability_plot.legend()

        plt.tight_layout()                                          # auto-adjust everything and hope for the best

        if os.path.exists(PLOTFILE):                                # save file to disk
            base_name, _ = os.path.splitext(PLOTFILE)
            bak_name = f"{base_name}.bak"
            if os.path.exists(bak_name):
                os.remove(bak_name)
            os.rename(PLOTFILE, bak_name)

        plt.savefig(PLOTFILE)
        plt.show()


    def print_generation_log(self):
        """
        Generate screen output from the log file.
        """

        if not self.log_data:
            print("No data to display.")
            return

        for tone_index, entry in enumerate(self.log_data):
            print(f"--- Tone {tone_index + 1} ---")
            if "matrix_name" in entry:
                print(f"Adjacency Matrix: {entry['matrix_name']}")

            if "primary_voice" in entry:
                print(f"Primary Voice   : {entry['primary_voice']}")

            if "overflow_counter" in entry:
                print(f"Overflow Counter: {entry['overflow_counter']}")

            if "current_note" in entry and "next_note" in entry:
                print(f"Current note    : {entry['current_note']:02} {PITCH_NAMES[entry['current_note']]}")
                print(f"Next note       : {entry['next_note']:02} {PITCH_NAMES[entry['next_note']]}")

            if "probability_sum" in entry:
                print(f"Probability sum : {entry['probability_sum']}")

            if "random_number" in entry:
                print(f"Random number   : {entry['random_number']}")

            if "running_sum" in entry:
                print(f"Running sum     : {entry['running_sum']}\n")