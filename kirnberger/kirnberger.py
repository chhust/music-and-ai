"""
Johann Philipp Kirnberger
Der allezeit fertige Polonoisen- und Menuettencomponist
Berlin (Georg Ludwig Winter), 1757

This program simulates Kirnberger's chance operations with the original source material.
Users can generate both minuets (1D6) and polonaises (1D6 and 2D6), and play them via MIDI.

==============
= Core files =
==============

File name                  | Description
-------------------------------------------------------
kirnberger.py              | this code
kirnberger_data.py         | construction data
kirnberger_dice_utils.py   | dice rolling logic
kirnberger_midi_utils.py   | MIDI operation
kirnberger_visual_utils.py | Pygame visualization logic

================
= Data folders =
================

MIDI files are expected in the subfolders "midi_m", "midi_p" and "midi_t".

====================
= Additional files =
====================

File name                  | Description
-------------------------------------------------------
analyzer.py                | basic analysis function
data_integrity.py          | data integrity check
"""


import pygame
import sys

from kirnberger_data import (polonaise_p1_1d, polonaise_p2_1d, polonaise_p1_2d, polonaise_p2_2d,
                             menuet_p1, menuet_p2, trio_p1, trio_p2)
from kirnberger_dice_utils import roll_dice
from kirnberger_midi_utils import play_midi_file, create_combined_midi
from kirnberger_visual_utils import initialize_pygame, visualize_minuet, visualize_polonaise


def generate_polonaise(number_of_dice=1):
    if number_of_dice not in [1, 2]:
        raise ValueError(f"Illegal number of dice: {number_of_dice}. Must be 1 or 2.") # no sense in continuing

    part1, part2 = [], []

    dict_p1 = polonaise_p1_1d if number_of_dice == 1 else polonaise_p1_2d
    dict_p2 = polonaise_p2_1d if number_of_dice == 1 else polonaise_p2_2d

    for key in sorted(dict_p1.keys(), key=int):                 # Part 1
        dice_roll  = roll_dice(number_of_dice)
        bars_list  = dict_p1[key]
        # dice_roll would be 1...6 for 1D or 2...12 for 2D, therefore the subtraction to avoid index errors
        bar_number = bars_list[dice_roll - number_of_dice]
        part1.append((key, dice_roll, bar_number))

    for key in sorted(dict_p2.keys(), key=int):                 # Part 2
        dice_roll  = roll_dice(number_of_dice)
        bars_list  = dict_p2[key]
        bar_number = bars_list[dice_roll - number_of_dice]
        part2.append((key, dice_roll, bar_number))

    part3 = part1[2:6]                                          # Part 3 repeats bars 3-6 from Part 1
    part3 = [(f"R{orig[0]}", orig[1], orig[2]) for orig in part3]           # mark with R

    return (part1 + part2 + part3), number_of_dice


def generate_minuet():
    result = []

    repetition_start = len(result)
    for key in sorted(menuet_p1.keys(), key=int):
        dice_roll = roll_dice()
        result.append((key, dice_roll, menuet_p1[key][dice_roll - 1]))      # 1...6 -> 0...5

    for key in sorted(menuet_p2.keys(), key=int):
        dice_roll = roll_dice()
        result.append((key, dice_roll, menuet_p2[key][dice_roll - 1]))
    repetition_end = len(result)

    for key in sorted(trio_p1.keys(), key=int):
        dice_roll = roll_dice()
        result.append((key, dice_roll, trio_p1[key][dice_roll - 1]))

    for key in sorted(trio_p2.keys(), key=int):
        dice_roll = roll_dice()
        result.append((key, dice_roll, trio_p2[key][dice_roll - 1]))

    # Repeat the Minuet part
    result.extend(result[repetition_start:repetition_end])

    return result


def get_instructions():
    return [
        "Press M for a new Minuet.",
        "Press 1 for a 1D6 Polonaise.",
        "Press 2 for a 2D6 Polonaise.",
        "Press P to play the composition.",
        "Press ESC to quit."
    ]


def main():
    screen, width, height = initialize_pygame()

    # Initialize output
    composition_type = "polonaise"
    dice_used = 1
    results, _         = generate_polonaise(dice_used)
    results_with_dice  = (results, dice_used)               # I need this as a tuple later
    drawing_function   = visualize_polonaise

    building_blocks = {
        "polonoise_p1_1d": polonaise_p1_1d,                 # That's how Kirnberger spelled it, no "noise" pun intended!
        "polonoise_p1_2d": polonaise_p1_2d,
        "polonoise_p2_1d": polonaise_p2_1d,
        "polonoise_p2_2d": polonaise_p2_2d
    }

    clock = pygame.time.Clock()
    running = True

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False

                elif event.key == pygame.K_m:
                    composition_type = "menuet"
                    results = generate_minuet()
                    results_with_dice = (results, None)
                    drawing_function = visualize_minuet
                    building_blocks = {
                        "menuet_p1": menuet_p1,
                        "menuet_p2": menuet_p2,
                        "trio_p1": trio_p1,
                        "trio_p2": trio_p2
                    }

                elif event.key in [pygame.K_1, pygame.K_2]:
                    composition_type = "polonaise"
                    dice_used = 1 if event.key == pygame.K_1 else 2
                    results, _ = generate_polonaise(dice_used)
                    results_with_dice = (results, dice_used)
                    drawing_function = visualize_polonaise
                    building_blocks = {
                        "polonoise_p1_1d": polonaise_p1_1d,
                        "polonoise_p1_2d": polonaise_p1_2d,
                        "polonoise_p2_1d": polonaise_p2_1d,
                        "polonoise_p2_2d": polonaise_p2_2d
                    }

                elif event.key == pygame.K_p:
                    if composition_type == "polonaise":
                        midi_path = create_combined_midi(results_with_dice[0], "polonaise")
                    else:
                        midi_path = create_combined_midi(results_with_dice[0], "menuet")

                    play_midi_file(midi_path)

        if composition_type == "polonaise":
            drawing_function(screen, width, results_with_dice, building_blocks)
        else:
            drawing_function(screen, width, results, building_blocks)

        font = pygame.font.SysFont("Arial", 16)

        for i, text in enumerate(get_instructions()):
            line = font.render(text, True, (0, 0, 0))
            screen.blit(line, (10, height - 110 + i * 20))

        pygame.display.flip()
        clock.tick(30)

    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    main()