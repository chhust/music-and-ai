# Generation Settings

INITIAL_PROGRESSION_LENGTH =  24                    # minimum length of generated melody, can be extended by ...
MAX_EXTENSION              =  10                    # ... this number of additional notes
TONIC_NOTE                 =   0                    # pitch class of initial and final note


# File Paths

MARKOV_FILE = "adjacency_matrices.json"             # filename of the adjacency matrices
OUTPUT_FILE = "OUTPUT/markov_audio_output.wav"      # filename for audio output
LOGFILE     = "OUTPUT/markov_logfile.json"          # JSON logfile
PLOTFILE    = "OUTPUT/markov_plotfile.png"          # PNG for plotting


# Audio Generation Settings

A4_FREQUENCY               = 440.0                  # frequency of A4 (440 Hz)
TONE_LENGTH                =    .4                  # length of tones in audio generation, in seconds


# Music-Related Constants

PITCH_CLASSES              =  12                    # twelve pitch classes per octave
PITCH_NAMES                = [                      # pitch class names (for text output)
    "C ", "C#",
    "D ", "D#",
    "E ",
    "F ", "F#",
    "G ", "G#",
    "A ", "A#",
    "B "
]