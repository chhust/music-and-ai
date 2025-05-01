/****************************************************
 * NEURAL NETWORK -- OCR/OMR CLASSIFIER (C Version) *
 * Based on Softmax / Stochastic Gradient Descent   *
 * and a Single-Layer Perceptron Model.             *
 * More or less no commentary here. Everything is   *
 * explained ad nauseam in the Jupyter Notebook /   *
 * Python version.                                  *
 ****************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>       // only for the exp() in the softmax function
#include <time.h>       // only for srand(time(NULL))

#include "glyph_definitions.h"


const int TRAINING_ITERATIONS = 5000;
const double LEARNING_RATE = .01;

#define TEST_CASE test_glyph_A


typedef struct {                // this is needed for qsort()
    int class_index;
    double probability;
} Prediction;



void print_training_glyphs();
void evaluate_test_case(const int test_glyph[GLYPH_HEIGHT][GLYPH_WIDTH], double *weights, double *biases, int input_size, int num_classes);
void initialize_weights_and_biases(double *weights, double *biases, int size, int classes);
void train_network(double *weights, double *biases, int input_size, int num_classes);
void train_model(const int *glyph_input, double *weights, double *biases, int input_size, int num_classes, int target_class);
double softmax(double *logits, int num_classes, int class_index);
int compare_predictions_descending(const void *a, const void *b);



int main() {
    int glyph_size = GLYPH_WIDTH * GLYPH_HEIGHT;
    int glyph_num = NUM_GLYPHS;

    print_training_glyphs();

    double weights[glyph_num * glyph_size];
    double biases[glyph_num];
    initialize_weights_and_biases(weights, biases, glyph_size, glyph_num);

    train_network(weights, biases, glyph_size, glyph_num);

    evaluate_test_case(TEST_CASE, weights, biases, glyph_size, glyph_num);

    return 0;
}


/*****************
 * I/O FUNCTIONS *
 *****************/

void print_training_glyphs() {
    for (int glyph_index = 0; glyph_index < NUM_GLYPHS; glyph_index++) {
        for (int row = 0; row < GLYPH_HEIGHT; row++) {
            for (int column = 0; column < GLYPH_WIDTH; column++) {
                glyphs[glyph_index][row][column] == 0 ? printf(" ") : printf("*");
            }
            printf("\n");
        }
        printf("\n");
    }
}

void evaluate_test_case(const int test_glyph[GLYPH_HEIGHT][GLYPH_WIDTH], double *weights, double *biases, int input_size, int num_classes) {
    double logits[num_classes];
    Prediction predictions[num_classes];

    for (int glyph_index = 0; glyph_index < num_classes; glyph_index++) {
        logits[glyph_index] = biases[glyph_index];
        for (int row = 0; row < GLYPH_HEIGHT; row++) {
            for (int column = 0; column < GLYPH_WIDTH; column++) {
                logits[glyph_index] += test_glyph[row][column] * weights[glyph_index * input_size + row * GLYPH_WIDTH + column];
            }
        }
    }

    for (int row = 0; row < GLYPH_HEIGHT; row++) {                          // display the test glyph
        for (int column = 0; column < GLYPH_WIDTH; column++) {
            test_glyph[row][column] == 0 ? printf(" ") : printf("*");
        }
        printf("\n");
    }

    for (int glyph_index = 0; glyph_index < num_classes; glyph_index++) {
        predictions[glyph_index].class_index = glyph_index;
        predictions[glyph_index].probability = softmax(logits, num_classes, glyph_index);
    }
    qsort(predictions, num_classes, sizeof(Prediction), compare_predictions_descending);

    printf("Top Five Results:\n");                                  // display results
    for (int i = 0; i < 5; i++) {
        printf("'%1d': Probability %6.2f %%\n", predictions[i].class_index, predictions[i].probability * 100);
    }
}


/******************
 * TRAINING LOGIC *
 ******************/

void initialize_weights_and_biases(double *weights, double *biases, int size, int classes) {
    srand(time(NULL));

    for (int weight_index = 0; weight_index < size * classes; weight_index++) {
        weights[weight_index] = ((double) rand() / (RAND_MAX + 1.0)) - 0.5;
    }
    for (int glyph_index = 0; glyph_index < classes; glyph_index++) {
        biases[glyph_index] = ((double) rand() / (RAND_MAX + 1.0)) - 0.5;
    }
}

void train_network(double *weights, double *biases, int input_size, int num_classes) {
    for (int iteration = 0; iteration < TRAINING_ITERATIONS; iteration++) {
        int example_index = iteration % NUM_GLYPHS;     // cycle through the array
        train_model(&glyphs[example_index][0][0], weights, biases, input_size, num_classes, example_index);
    }
}

void train_model(const int *glyph_input, double *weights, double *biases, int input_size, int num_classes, int target_class) {
    double *logits = malloc(num_classes * sizeof(double));

    // Forward Pass: calculate logits per class
    for (int class_index = 0; class_index < num_classes; class_index++) {
        logits[class_index] = biases[class_index];
        for (int feature_index = 0; feature_index < input_size; feature_index++) {
            logits[class_index] += glyph_input[feature_index] * weights[class_index * input_size + feature_index];
        }
    }

    // Backward Pass: check errors, update weights and biases accordingly
    for (int class_index = 0; class_index < num_classes; class_index++) {
        double probability = softmax(logits, num_classes, class_index);
        double error = (class_index == target_class) ? probability - 1.0 : probability;

        for (int feature_index = 0; feature_index < input_size; feature_index++) {
            weights[class_index * input_size + feature_index] -= LEARNING_RATE * error * glyph_input[feature_index];
        }

        biases[class_index] -= LEARNING_RATE * error;
    }

    free(logits);
}


/********************
 * HELPER FUNCTIONS *
 ********************/

double softmax(double *logits, int num_classes, int class_index) {
    double sum_exp = 0.0;

    // Calculate the sum of exponential values of all logits
    for (int i = 0; i < num_classes; i++) {
        sum_exp += exp(logits[i]);
    }

    return exp(logits[class_index]) / sum_exp;
}

int compare_predictions_descending(const void *a, const void *b) {
    double prob_a = ((Prediction *)a)->probability;
    double prob_b = ((Prediction *)b)->probability;
    return (prob_b > prob_a) - (prob_b < prob_a);   // descending order
}