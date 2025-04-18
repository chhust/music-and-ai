import random

def calculate_two_dice_probabilities():
    """
    This calculates probabilities for rolling 2D6.
    Basically, it could be hard-coded values, but I wanted to show off!
    """

    counts = {}
    total = 0

    for die1 in range(1, 7):
        for die2 in range(1, 7):
            roll_sum = die1 + die2
            if roll_sum in counts:
                counts[roll_sum] += 1
            else:
                counts[roll_sum] = 1
            total += 1                      # for 6x6 combinations = 36

    return {
        roll_sum: counts[roll_sum] / total for roll_sum in sorted(counts)
    }

TWO_DICE_PROBS = calculate_two_dice_probabilities()


def roll_dice(number=1, sides=6):
    """
    Roll xDy
    """

    if number < 1 or sides < 2 or not isinstance(sides, int) or not isinstance(number, int):
        raise ValueError(f"You cannot roll {number}D{sides}.")

    return sum(
        random.randint(1, sides) for _ in range(number)
    )