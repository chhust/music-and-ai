import os
import pygame

from mido import MidiFile, MidiTrack, merge_tracks


def play_midi_file(path):
    """
    Play a MIDI file with pygame.

    Possible errors will not let the code crash.
    """

    try:                                                # initialize the audio setup
        if not pygame.mixer.get_init():
            pygame.mixer.init()
    except pygame.error as e:
        print(f"Pygame mixer initialization failed: {e}.")
        return

    try:                                                # play output file
        pygame.mixer.music.load(path)
        pygame.mixer.music.play()
    except pygame.error as e:
        print(f"Pygame music playback failed: {e}.")


def create_combined_midi(results, composition_type, output_path="composition.mid"):
    """
    Construct the output file and save it to disk.
    """

    menuet_folder, trio_folder, polonaise_folder = "midi_m", "midi_t", "midi_p"

    if composition_type not in ["menuet", "polonaise"]:     # precaution -- this can't ever happen in the current code
        raise ValueError("Unknown composition type.")       # this will crash bc it must be a program logic error

    combined_midi  = MidiFile()                             # start a new MIDI project
    combined_track = MidiTrack()
    combined_midi.tracks.append(combined_track)

    # The files are labeled "1.mid", "2.mid", etc. They are stored in the folders defined above.
    # Each result is a three-element tuple: (bar_label, dice_roll, section_number)
    for counter, (_, _, section_number) in enumerate(results):  # I do not need the bar labels and dice rolls
        if composition_type == "polonaise":                 # Polonaise
            midi_path = os.path.join(polonaise_folder, f"{section_number}.mid")
        elif composition_type == "menuet":                  # Minuet
            if counter < 16:                                # ------, Part 1
                midi_path = os.path.join(menuet_folder, f"{section_number}.mid")
            elif counter < 32:                              # ------, Part 2 (Trio)
                midi_path = os.path.join(trio_folder, f"{section_number}.mid")
            else:                                           #-------, Part 3 = Part 1
                midi_path = os.path.join(menuet_folder, f"{section_number}.mid")

        if not os.path.exists(midi_path):
            print(f"File not found: {midi_path}.")          # skip missing files
            continue

        part_midi = MidiFile(midi_path)
        for message in merge_tracks(part_midi.tracks):      # MIDI consists of "messages" (play note, end note, ...)
            combined_track.append(message)

    combined_midi.save(output_path)                         # save to disk
    return output_path