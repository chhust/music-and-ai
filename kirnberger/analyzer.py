import os
import pretty_midi
import matplotlib.pyplot as plt

from kirnberger_data import (
    polonaise_p1_1d, polonaise_p2_1d, polonaise_p1_2d, polonaise_p2_2d,
    menuet_p1, menuet_p2, trio_p1, trio_p2
)


SOURCE_MATERIAL = "polonaise_p1_2d"             # other folders are possible as well

DISPLAY_SETTINGS = {                            # This is the central settings dictionary
    "OVERALL_TONALITY"   : True,
    "FILE_LEVEL_TONALITY": True,
    "NOTE_HISTOGRAM"     : True,
    "RHYTHMIC_DENSITY"   : True
}


MATERIALS = globals().get(SOURCE_MATERIAL)
if MATERIALS is None:
    raise ValueError(f"Unknown source material: {SOURCE_MATERIAL}")

if SOURCE_MATERIAL.startswith("polonaise"):
    BASE_PATH = "midi_p"
elif SOURCE_MATERIAL.startswith("menuet"):
    BASE_PATH = "midi_m"
elif SOURCE_MATERIAL.startswith("trio"):
    BASE_PATH = "midi_t"
else:
    raise ValueError(f"Could not determine folder for {SOURCE_MATERIAL}")

NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def build_file_paths(groups):
    """
    Construct full file paths
    """

    return {
        group: [os.path.join(BASE_PATH, f"{num}.mid") for num in nums]
        for group, nums in groups.items()
    }


def load_midi_files(files):
    """
    Load a list of MIDI files, extract notes and rhythms.
    """

    notes, rhythms = [], []
    for file in files:
        try:
            midi = pretty_midi.PrettyMIDI(file)
            for inst in midi.instruments:
                for note in inst.notes:
                    notes.append(note.pitch)
                    rhythms.append(note.start)
        except Exception as e:
            print(f"Error loading {file}: {e}")
    return notes, rhythms


def note_histogram(notes):
    """
    Create a histogram of MIDI note occurrences
    """

    return [notes.count(p) for p in range(128)] if notes else [0]*128


def pitch_class_histogram(notes):
    """
    Create a histogram of pitch classes
    """

    pc = [n % 12 for n in notes]
    return [pc.count(i) for i in range(12)]


def visualize_note_histogram(counts, title):
    """
    Draw a histogram
    """

    if DISPLAY_SETTINGS["NOTE_HISTOGRAM"]:
        plt.figure()
        plt.bar(NOTE_NAMES, counts)
        plt.title(f"Note Frequency – {title}")
        plt.xlabel("Pitch Class")
        plt.ylabel("Count")
        plt.show()


def estimate_tonal_center(counts):
    """
    Estimate a tonal center based on triad scores.
    A nice addition might be searching for D7 chords as well.
    """

    def triad_score(root, is_major):
        steps = (0, 4, 7) if is_major else (0, 3, 7)
        return sum(counts[(root + step) % 12] for step in steps)

    scores = [(index, triad_score(index, True), triad_score(index, False)) for index in range(12)]
    best_major = max(scores, key=lambda x: x[1])
    best_minor = max(scores, key=lambda x: x[2])

    return (
        (best_major[0], "maj", best_major[1]) if best_major[1] >= best_minor[2]
        else (best_minor[0], "min", best_minor[2])
    )


def calculate_density(rhythms):
    """
    Calculate the event density, measured as notes per second.
    """

    if len(rhythms) < 2:
        return 0

    duration = max(rhythms) - min(rhythms)
    return len(rhythms) / duration if duration > 0 else 0


def pitch_class_name(n):
    """
    Map pitch class set to note name.
    """

    return NOTE_NAMES[n % 12]


def analyze_group(files, label):
    """
    Run a series of analyses on a group of files: pitch distribution, event density, tonal center estimation.
    """

    notes, rhythms = load_midi_files(files)
    counts = pitch_class_histogram(notes)
    density = calculate_density(rhythms)
    best_tonal_center = estimate_tonal_center(counts)
    visualize_note_histogram(counts, label)

    return counts, density, best_tonal_center


def visualize_tonal_centers(results):
    """
    Show a bar chart of most likely tonal centers.
    """

    names = list(results.keys())
    scores = [results[n][2] for n in names]
    labels = [f"{pitch_class_name(results[n][0])}{results[n][1]}" for n in names]

    plt.figure()
    bars = plt.bar(names, scores)
    plt.title("Best Tonal Center per Group")
    plt.ylabel("Matching Score")
    for bar, label in zip(bars, labels):
        plt.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), label, ha="center", va="bottom")

    plt.show()


def analyze_file(file):
    """
    Analyze a single file.
    """

    notes, _ = load_midi_files([file])
    counts = pitch_class_histogram(notes)

    return estimate_tonal_center(counts)


def visualize_file_tonal_centers(groups):
    """
    Show estimated tonal centers for each file in a group.
    """

    for group, files in groups.items():
        labels, scores, display = [], [], []

        for file in files:
            root, quality, score = analyze_file(file)
            labels.append(f"{pitch_class_name(root)}{quality}")
            scores.append(score)
            display.append(os.path.basename(file))

        plt.figure()
        bars = plt.bar(range(len(files)), scores, tick_label=display)
        plt.title(f"Tonal Centers – {group}")
        plt.ylabel("Matching Score")

        for i, bar in enumerate(bars):
            plt.text(bar.get_x() + bar.get_width() / 2, bar.get_height(),
                     labels[i], ha="center", va="bottom")
        plt.xticks(rotation=90)
        plt.tight_layout()

        plt.show()


def visualize_event_density(densities):
    """
    Show event densities for each group.
    """

    groups = list(densities.keys())
    values = list(densities.values())
    plt.figure()
    plt.bar(groups, values)
    plt.title("Rhythmic Density per Group")
    plt.ylabel("Notes / Second")

    plt.show()


def main():
    file_groups = build_file_paths(MATERIALS)
    group_results, best_tonal_centers = {}, {}

    for name, files in file_groups.items():
        if DISPLAY_SETTINGS["OVERALL_TONALITY"] or DISPLAY_SETTINGS["FILE_LEVEL_TONALITY"]:
            counts, density, best = analyze_group(files, name)
            group_results[name] = density
            best_tonal_centers[name] = best

    if DISPLAY_SETTINGS["OVERALL_TONALITY"]:
        visualize_tonal_centers(best_tonal_centers)

    if DISPLAY_SETTINGS["FILE_LEVEL_TONALITY"]:
        visualize_file_tonal_centers(file_groups)

    if DISPLAY_SETTINGS["RHYTHMIC_DENSITY"]:
        visualize_event_density(group_results)


if __name__ == "__main__":
    main()