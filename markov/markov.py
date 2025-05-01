"""
This program uses a Markov chain to generate a sequence of musical notes.
The probability of moving from one note to another is defined by a 2D adjacency matrix stored in a JSON file.
Different adjacency matrices construct weighted directed graphs for different styles.

"A Markov chain or Markov process is a stochastic model describing a sequence of possible events
 in which the probability of each event depends only on the state attained in the previous event.
 Informally, this may be thought of as, 'What happens next depends only on the state of affairs now.'"
(https://en.wikipedia.org/wiki/Markov_chain)

More information on Markov chains and music:
https://towardsdatascience.com/markov-chain-for-music-generation-932ea8a88305

Cf. Charles Ames, "The Markov Process as a Compositional Model: A Survey and Tutorial," in: "Leonardo" 22/2 (1989),
                   pp. 175-187, https://doi.org/10.2307/1575226.

More info about Markov chains, but far exceeding what I do in this code:

James R. Norris, "Markov Chains," Cambridge, etc: Cambridge University Press, 1998
                  (Cambridge Series in Statistical and Probabilistic Mathematics, 2).

Nicolas Privault, "Understanding Markov Chains: Examples and Applications," Singapore: Springer, 2013, 2nd ed., 2018.

Both are far more advanced than what I do, and I didn't read beyond the introductory chapters in both cases –
which already brought more than I neede for the code.

There was a chapter on Markov chains for text generation in JavaScript in:

Pit Noack and Sofia Sanner, "Künstliche Intelligenz verstehen: Eine spielerische Einführung,"
                             Bonn: Rheinwerk, 2023, pp. 29-49.

And everything about JSON comes from

Lindsay Bassett, "Introduction to JavaScript Object Notation. A To-the-Point Guide to JSON,"
                  Beijing, etc.: O'Reilly, 2015.

Books about data visualization are mentioned in the relevant module.
"""


from matrix_visualizer       import *
from markov_music_generator  import *
from counterpoint_generators import *
from output_generator        import *


print("MARKOV CHAIN MUSIC GENERATOR")
print("============================\n")

if not os.path.exists("OUTPUT"):
    os.makedirs("OUTPUT")

generator = MarkovMusicGenerator(MARKOV_FILE)

if generator.set_adjacency_matrix():                                                        # choose adjacency matrix
    matrix_visualizer = MatrixVisualizer(generator.adjacency_matrix, generator.matrix_name)
    matrix_visualizer.visualize_adjacency_matrix()

    primary = generator.generate_melody()                                                   # generate primary voice

    print()
    counterpoint_generator = CounterpointGenerator(primary, generator.adjacency_matrix)     # choose counterpoint generator
    secondary = counterpoint_generator.choose_counterpoint_method()                         # choose secondary voice

    if secondary:
        print()

        text_output = TextOutputGenerator(primary, secondary)
        text_output.display_output()                                                        # show text output

        audio_output = AudioOutputGenerator(sample_path="samples")
        try:
            audio_output.play_melody(primary, secondary, note_duration=TONE_LENGTH)         # play audio output
        except Exception as e:
            print(f"Audio output problem:\n{e}")
        print()

    if not input("\nPress ENTER to show primary voice statistics (q to quit). ").strip().lower().startswith("q"):
        statistics = JSONOutputGenerator()
        statistics.print_generation_log()
        statistics.plot_melody(generator.adjacency_matrix)

print("\nAll done. Goodbye!")
