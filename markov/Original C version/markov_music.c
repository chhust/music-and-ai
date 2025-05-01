/***************************************************************
 *                                                             *
 * markov_music.c:  This is the original C implementation of   *
 *                  my Python demo Markov music generator.     *
 *                  Written in 2023. I reduced the comments as *
 *                  most of the core functionality is quite    *
 *                  similar to the Python version.             *
 *                                                             *
 * Key differences: The C code has fewer counterpoint options. *
 *                  The C code does low-level audio synthesis  *
 *                      that goes directly into a WAV file.    *
 *                  And... it's way cooler, because it's C. :) *
 *                                                             *
 ***************************************************************/

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "adjacency_matrices.h"


// These definitions act as a switch to control which adjacency matrix will be used.
// Matrices C (chromatic, random) and E (diatonic, strictly step-wise) will not work with the counterpoint algorithm.

#define USE_MATRIX_A                // Diatonic, predominately step-wise
//#define USE_MATRIX_B              // Diatonic, random
//#define USE_MATRIX_D              // Octatonic, random


// These definitions act as a switch to control the waveform for the counterpoint melody.

#define COUNTERPOINT_SINE           // Control switch for sine waves
//#define COUNTERPOINT_SQUARE       // Control switch for square waves
//#define COUNTERPOINT_SAWTOOTH     // Control switch for sawtooth waves
//#define COUNTERPOINT_TRIANGLE     // Control switch for triangle waves


// PITCH_CLASSES should be left at 12

#define PITCH_CLASSES 12            // 12 pitch classes from C to B
#define TONIC_NOTE 0                // Which pitch class is handled as the tonic?


// DURATION of output tones in seconds may be varied, SAMPLE_RATE should be left at 44,100, and MAX_AMPLITUDE should be left at 32,767

#define DURATION .5                 // Duration of each note in seconds
#define SAMPLE_RATE 44100           // Sample rate is 44,100 Hz (= 44,100 /s)
#define MAX_AMPLITUDE 32767         // Maximum amplitude


// Check for PI definition, define M_PI if necessary

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


// Output file name and parameter

#define FILE_NAME "markov_output.wav"
//#define DRIVE_ME_CRAZY            // Inverts channels after each note. Sounds horrible!


// Melody parameters and adjacency matrix preparation

#define ORIGINAL_LENGTH 40          // Length of melodies to be generated
#define MAX_EXTENSION 20            // Maximum extension of melody at the end
int adjacency_matrix[PITCH_CLASSES][PITCH_CLASSES];
int melody_length = ORIGINAL_LENGTH;


// Function prototypes:
// - tone progression generation and output,
// - audio output and WAV header creatio,
// - utility functions for frequency calculation and adjacency chain selection

bool generate_melody(int* melody);                                              // Markov chain generation
void generate_secondary_voice(int* melody, int* counterpoint);                  // Secondary voice generation ...
int third_below(int primary);                                                   // ... uses an algorithm to create lower thirds
void print_result(int* melody, int* counterpoint);                              // Written output

bool audio_output(int* melody, int* counterpoint);                              // Write data to output file
void write_wav_header(FILE* output_file, int sample_rate, int total_samples);   // Audio file creation

void fill_frequencies(double* frequencies);                                     // Create frequency table
double calculate_frequency(int midi_note);                                      // Calculate a note frequency
bool set_adjacency_matrix();                                                    // Select adjacency matrix


// main() initializes some values, generates a melody, and writes the output to a file.

int main() {
    printf("Two-dimensional Markov music generator with audio output.\n\n");
    srand(time(NULL));
    if(set_adjacency_matrix() == false) {
        printf("Undefined adjacency matrix error.\n");
        return 1;
    }

    int* melody = malloc(sizeof(int) * (melody_length + MAX_EXTENSION));
    int* counterpoint = malloc(melody_length * sizeof(int));
    if(!melody || !counterpoint) {
        printf("Memory allocation error.\n");
        return 1;
    }

    printf("Initial melody length is %d.\n", melody_length);
    if(generate_melody(melody) == false) {
        printf("Adjacency matrix data error.\n");
    }
    printf("Melody plus appendix length is %d.\n", melody_length);

    generate_secondary_voice(melody, counterpoint);

    print_result(melody, counterpoint);
    
    if(audio_output(melody, counterpoint) == false) {
        printf("Audio output error.\n");
        free(melody);
        free(counterpoint);
        return 1;
    } else {
        free(melody);
        free(counterpoint);
        printf("Program finished successfully.\n");
        return 0;
    }
}


// This function generates the tone progression.
// It starts with a random diatonic note and then uses the selected adjacency matrix to probabilistically determine each subsequent note.
// Return values indicate success or failure.
// For details about the Markov process, check the comments in the Python version.

bool generate_melody(int* melody) {
    printf("Generating melody data... ");

    int probability_sum, random_number, next_note, current_note;
    int overflow_counter = 0;   // counts melody_length extensions
    
    // Create random diatonic starting note
    do {
         current_note = rand() % PITCH_CLASSES;
    } while(!(current_note == 0 || current_note == 2 || current_note == 4 || current_note == 5 || current_note == 7 || current_note == 9 || current_note == 11));
    melody[0] = current_note;

    for(int i = 1; i < melody_length; i++) {
        probability_sum = 0;
        for(int j = 0; j < PITCH_CLASSES; j++) {
            probability_sum += adjacency_matrix[current_note][j];
        }

        if (probability_sum == 0) {
            return false;
        }

        random_number = rand() % probability_sum;
        next_note = 0;

        while(random_number >= adjacency_matrix[current_note][next_note]) {
            random_number -= adjacency_matrix[current_note][next_note];
            next_note++;
        }

        melody[i] = next_note;          // keep track of result and move on
        current_note = next_note;

        if((i >= (ORIGINAL_LENGTH - 1)) && (melody[i] != TONIC_NOTE)) {     // extend melody until it reaches tonic
            if(++overflow_counter >= MAX_EXTENSION) {
                melody[++i] = TONIC_NOTE;
            }
            melody_length++;        // melody_length is global, so this is not very elegant
        }
    }
    printf("Done.\n");
    return true;
}


// This function iterates the melody, creating lower thirds below

void generate_secondary_voice(int* melody, int* counterpoint) {
    for(int i = 0; i < melody_length; i++) {
        counterpoint[i] = third_below(melody[i]);
    }
}


// This function creates lower thirds below the first note, capping at C [which is pitch class 0] as a lower border.
// There could be different algorithms here for different output.
// Again, check the Python version for more comments

int third_below(int primary) {
    if(primary == 0) {      // cap at C
        return 0;
    }

    int secondary = primary;

    for(int step = 0; step < 2; ) {
        secondary = (secondary - 1 + PITCH_CLASSES) % PITCH_CLASSES;
        if (adjacency_matrix[primary][secondary]) {
            step++;
        }
    }

    return secondary;
}


// This function prints the tone progression.

void print_result(int* melody, int* counterpoint) {
    char note_names[12][3] = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" };   // Define note names (only #, no b)

    for(int i = 0; i < melody_length; i++) {
        if(i == ORIGINAL_LENGTH) {
            printf("\n");
        }
        printf("%2d: %s - %s", i + 1, note_names[melody[i]], note_names[counterpoint[i]]);
        (i % 2) ? printf("\n") : printf("\t\t");
    }
    if (melody_length % 2) printf("\n");
}


// This function writes the audio output into a WAV file.
// I took a lot of inspiration from "The Audio Programming Book," ed. by Richard Boulanger and Victor Lazzarini, foreword by Max Mathews,
//                                                                Cambridge and London: MIT Press, 2011.

bool audio_output(int* melody, int* counterpoint) {
    printf("Generating output... ");
    FILE *audio_output = fopen(FILE_NAME, "wb");
    if (!audio_output) {
        return false;
    }

    // Data amount: (rate * duration) = (samples / note) per channel, so twice for stereo
    int number_of_samples = 2 * (SAMPLE_RATE * DURATION * melody_length);
    write_wav_header(audio_output, SAMPLE_RATE, number_of_samples);

    double melody_frequencies[PITCH_CLASSES], counterpoint_frequencies[PITCH_CLASSES];              // Generate frequency tables
    
    fill_frequencies(melody_frequencies);
    fill_frequencies(counterpoint_frequencies);

    double melody_phase = 0.0, counterpoint_phase = 0.0;                                            // Initialize both phases to zero

    for(int position_in_melody = 0; position_in_melody < melody_length; position_in_melody++) {     // Iterate generated melody
        double melody_frequency       = melody_frequencies[melody[position_in_melody]];
        double counterpoint_frequency = counterpoint_frequencies[counterpoint[position_in_melody]];
        
        for(int j = 0; j < SAMPLE_RATE * DURATION; j++) {                                           // Calculate sine wave for single note
            // Calculate the current phase of the sine wave = current point of the sine wave:
            // "2.0 * PI * frequency" converts value in Hertz to radial frequency: "/s" --> "rad/s"; 2 * PI = one sine wave cycle
            // Dividing the radial frequency by SAMPLE_RATE adjusts this to the number of samples per second to be generated,
            // and multiplying this with j calculates the correct phase for the current time
            // This will be added to the previous phase to avoid phase discontinuity and resulting cracks between different tones.
            // The last phase of one note is taken over to the next note, avoiding any audio cracks.
            melody_phase += (2.0 * M_PI * melody_frequency) / SAMPLE_RATE;
            counterpoint_phase += (2.0 * M_PI * counterpoint_frequency) / SAMPLE_RATE;

            if (melody_phase > 2.0 * M_PI) {                                                        // Keep phases in range 0 ... (2 * PI)
                melody_phase -= 2.0 * M_PI;
            }
            if (counterpoint_phase > 2.0 * M_PI) {
                counterpoint_phase -= 2.0 * M_PI;
            }

            int16_t melody_sample = (int16_t) (MAX_AMPLITUDE * sin(melody_phase));
            int16_t counterpoint_sample;

            #ifdef COUNTERPOINT_SINE
                counterpoint_sample = (int16_t) (MAX_AMPLITUDE * sin(counterpoint_phase));
            #endif

            #ifdef COUNTERPOINT_SQUARE
                // If the current sine wave phase is below / over 0, it is set to minimum / maximum values to convert it to square waveform.
                // The max amplitude of 32,767 is modified to create a feasible loudness impression.
                if (sin(counterpoint_phase) >= 0) {
                    counterpoint_sample =  MAX_AMPLITUDE / 20;
                } else {
                    counterpoint_sample = -MAX_AMPLITUDE / 20;
                }
            #endif

            #ifdef COUNTERPOINT_SAWTOOTH
                // Sawtooth waves range linearly from -1 ... 1 during one period (2 * PI).
                // The phase is used to determine the position within the waveform:
                // "normalized_phase" maps counterpoint_phase to a range 0 ... 1.
                // "sawtooth_value" shifts the range to -.5 ... .5 and scales to -1 ... 1.
                // "counterpoint_sample" multiplies this by a max amplitude to create an acceptable loudness impressiom.
                double normalized_phase = counterpoint_phase / (2.0 * M_PI);
                double sawtooth_value = 2.0 * (normalized_phase - 0.5);
                counterpoint_sample = (int16_t) (MAX_AMPLITUDE / 4 * sawtooth_value);
            #endif

            #ifdef COUNTERPOINT_TRIANGLE
                // Triangle waves rise and fall linearly within ranges -1 ... 1 ... -1 during one period (2 * PI).
                // The phase is used to determine the position and slope (rising or falling) in the waveform:
                // "normalized_phase" maps counterpoint_phase to a range 0 ... 1.
                // If this is < 0.5, we are in the part during which the wave rises from -1 ... +1.
                //             else, we are in the part during which the wave falls from +1 ... -1.
                // A triangle wave is constructed by linearly increasing the wave's value in the first half and decreasing it in the second.
                double normalized_phase = counterpoint_phase / (2.0 * M_PI);
                double triangle_value;
                if (normalized_phase < 0.5) {
                    // "normalized_phase" represents the current phase, mapped to 0 ... 1.
                    //  At the start of the rising phase, this is 0, and it linearly increases to 0.5 at the middle of the wave's period.
                    // "4 * normalized_phase": As normalized_phase is in range 0 ... 0.5 while the wave rises, "* 4" stretches this to 0 ... 2.
                    //  This is necessary as the triangle wave covers a range -1 ... 1, so the rising part needs to go from -1 to 1.
                    // "- 1": This shifts the wave down from range 0 ... 2 to the result of -1 ... 1.
                    triangle_value =  4 * normalized_phase - 1; 
                } else {
                    // The second half of the triangle wave descends from 1 at the midpoint down to -1 at the end of the cycle.
                    // "normalized_phase", see above. During the falling phase, this is in range 0.5 ... 1.
                    // "-4 * normalized_phase" inverts and stretches the wave, mapping it to range -2 ... 0.
                    // "+ 3" shifts the wave up by 3, changing the range to 1 ... -1.
                    triangle_value = -4 * normalized_phase + 3;
                }
                counterpoint_sample = (int16_t) (MAX_AMPLITUDE * triangle_value);
            #endif

            #ifdef DRIVE_ME_CRAZY
                // Inverting the channel configuration at each note really drives one crazy! :))
                if(position_in_melody % 2) {
                    fwrite(&melody_sample, sizeof(melody_sample), 1, audio_output);                 // Write melody to left channel
                    fwrite(&counterpoint_sample, sizeof(counterpoint_sample), 1, audio_output);     // Write counterpoint to right channel
                } else {
                    fwrite(&counterpoint_sample, sizeof(counterpoint_sample), 1, audio_output);     // Write counterpoint to left channel
                    fwrite(&melody_sample, sizeof(melody_sample), 1, audio_output);                 // Write melody to right channel
                }
            #else
                fwrite(&melody_sample, sizeof(melody_sample), 1, audio_output);                     // Write melody to left channel
                fwrite(&counterpoint_sample, sizeof(counterpoint_sample), 1, audio_output);         // Write counterpoint to right channel
            #endif
        }
    }
    
    fclose(audio_output);                                                                           // Close file
    printf("Done.\n");
    return true;
}


// This function writes the WAV header information into "output_file". "sample_rate" and "total_samples"
// specify the audio resolution and the amount of data. Audio data itself is not written by this function.
// See https://www.mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html for WAV format specifications.

void write_wav_header(FILE* output_file, int sample_rate, int total_samples) {
    // Calculate byte_rate: sample rate * 2 bytes per sample * 2 16-bit channels
    // Generally, byte_rate = sample_rate * NumChannels * (BitsPerSample / 8) * 2 channels
    int byte_rate = sample_rate * 2 * 2;
    // Calculate size of the data chunk: total samples * 2 bytes per sample for 16-bit mono output
    int data_size = total_samples * 2 * 2;
    int chunk_size = 36 + data_size;

    // Prepare WAV file header information
    // RIFF:                  File contains "Resource Interchange File Format" data
    // data_size + 36, [...]: Size of entire file - 8 bytes ("RIFF" + size values) = remainder of this header plus actual data size,
    //                        low bytes before high bytes ("little endian" format)
    // WAVE:                  File containts waveform data, thus: wave audio file
    // fmt :                  Sub-chunk 1 ID is "format chunk", heading the format of following sound info
    // 16, 0, 0,0:            Size of sub-chunk 1 is 16 bytes; standard value for Pulse-Code Modulation (PCM) format; little endian format
    // 1, 0:                  Audio format – 1 for PCM, meaning the data will be uncompressed
    // 2, 0:                  NumChannels - 2 channel stereo ouput
    // sample_rate, [...]:    Sample rate (44,100 Hz in this demo), four-byte
    // byte_rate, [...]:      Byte rate, four-byte
    // 4, 0:                  BlockAlign info: number of bytes for one sample, including all channels. 4 for 16-bit stereo
    // 16, 0:                 BitsPerSample info: 16 for 16-bit samples
    // data:                  Sub-chunk 2 ID, marks beginning of data section
    // data_size, [...]:      Size of sub-chunk 2, four-byte
    // The "& 0xFF" operation is used to extract the lowest byte from a 32-bit integer. This is for writing multi-byte values in little-endian format:
    // ("Little-endian format" means that the "lowest", least significant byte is stored first, "low before high".)
    // For each 32-bit integer, the code writes the least significant byte first, then shifts the integer value 8 bits to the right
    // and again extracts the least significant byte, repeating this for all four bytes of the 32-bit integer value.
    // The AND operation with 1111 1111 serves as a bitwise masking, ensuring that the lowest eight bits stay as they were,
    // but averything else is "switched off" (set to 0).
    unsigned char header[] = {
        'R', 'I', 'F', 'F',                                                                         // "RIFF" chunk descriptor
        chunk_size  & 0xFF, (chunk_size  >> 8) & 0xFF, (chunk_size  >> 16) & 0xFF, (chunk_size  >> 24) & 0xFF,
        'W', 'A', 'V', 'E',                                                                         // "WAVE" format descriptor
        'f', 'm', 't', ' ',                                                                         // "fmt " subchunk format descriptor
        16, 0, 0, 0,
        1, 0,
        2, 0,
        sample_rate & 0xFF, (sample_rate >> 8) & 0xFF, (sample_rate >> 16) & 0xFF, (sample_rate >> 24) & 0xFF,
        byte_rate   & 0xFF, (byte_rate   >> 8) & 0xFF, (byte_rate   >> 16) & 0xFF, (byte_rate   >> 24) & 0xFF,
        4, 0,
        16, 0,
        'd', 'a', 't', 'a',                                                                         // "data" chunk descriptor
        data_size   & 0xFF, (data_size   >> 8) & 0xFF, (data_size   >> 16) & 0xFF, (data_size   >> 24) & 0xFF
    };

    fwrite(header, sizeof(header), 1, output_file);
}


// Iterate one octave to calculate frequencies

void fill_frequencies(double* frequencies) {
    for (int midi_note = 0; midi_note < 12; midi_note++) {                                          // From C4 to B4 = MIDI notes 60-71
        frequencies[midi_note] = calculate_frequency(60 + midi_note);
    }
}


// Calculate frequency from MIDI value
// Factor for each half-tone step is 2 ^ (1/12), twelfth root of 2, thus 12 half-tones add up to one octave
// A4 = 440 Hz (MIDI 69), so the code calculates the difference from this point to the current note as the factor that 440 is multiplied with

double calculate_frequency(int midi_note) {
    return 440.0 * pow(2.0, (midi_note - 69) / 12.0);
}


// Setup function: check which adjacency matrix has been defined in the code and copy its contents into the "adjacency_matrix" variable.
// This is not pretty and it surely would be nicer to get user input. But it's simple and, most important, it works.

bool set_adjacency_matrix() {
    #ifdef USE_MATRIX_A
        memcpy(adjacency_matrix, adjacency_matrix_A, sizeof(adjacency_matrix));
        return true;
    #elif defined USE_MATRIX_B
        memcpy(adjacency_matrix, adjacency_matrix_B, sizeof(adjacency_matrix));
        return true;
    #elif defined USE_MATRIX_C
        memcpy(adjacency_matrix, adjacency_matrix_C, sizeof(adjacency_matrix));
        return true;
    #elif defined USE_MATRIX_D
        memcpy(adjacency_matrix, adjacency_matrix_D, sizeof(adjacency_matrix));
        return true;
    #elif defined USE_MATRIX_E
        memcpy(adjacency_matrix, adjacency_matrix_E, sizeof(adjacency_matrix));
        return true;
    #else
        return false;
    #endif
}