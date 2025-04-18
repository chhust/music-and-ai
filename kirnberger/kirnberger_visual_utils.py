import pygame

from kirnberger_data import menuet_p1, menuet_p2, trio_p1, trio_p2
from kirnberger_dice_utils import TWO_DICE_PROBS


def initialize_pygame():
    """
    Initialize Pygame and set up the output window.
    """

    pygame.init()
    pygame.font.init()
    width, height = 1200, 600
    screen = pygame.display.set_mode((width, height))
    pygame.display.set_caption("Kirnberger Visualizer")

    return screen, width, height


def get_colors():
    """
    Give color definitions for the different parts of the pieces as a dictionary.
    """

    return {
        "polonaise_p1": (255, 150, 150),        # red
        "polonaise_p2": (150, 255, 150),        # green
        "menuet"      : (150, 150, 255),        # blue
        "trio"        : (255, 150, 255)         # pink
    }


def get_fonts():
    """
    Font definitions
    """

    return (
        pygame.font.SysFont("Arial", 14),
        pygame.font.SysFont("Arial", 24, bold=True)
    )


def draw_probability_scale(screen, x, y, cell_width, cell_height):
    """
    With 2D6, numbers appear with different probabilities: there's one possibility for 2 (1+1), but there are
    six possibilities for 7 (1+6, 2+5, 3+4, 4+3, 5+2, 6+1). This function draws a scale showing these probabilities.
    """

    font = pygame.font.SysFont("Arial", 10, bold=True)
    max_probability = max(TWO_DICE_PROBS.values())

    for index, total in enumerate(range(2, 13)):
        probability = TWO_DICE_PROBS[total]
        gray_tone = int(255 * (1 - probability / max_probability))
        color = (gray_tone, gray_tone, gray_tone)

        rect = pygame.Rect(x, y + index * cell_height, cell_width, cell_height)
        pygame.draw.rect(screen, color, rect)

        text_color = (255, 255, 255) if gray_tone < 128 else (0, 0, 0)      # readable text color should be contrasting
        label = font.render(f"{int(probability*100)} %", True, text_color)
        screen.blit(label, (
            x + cell_width // 2 - label.get_width() // 2,
            y + index * cell_height + cell_height // 2 - label.get_height() // 2)
        )


def visualize_polonaise(screen, width, results_with_dice, building_blocks):
    """
    Polonaise visualization.
    """

    results, dice = results_with_dice

    screen.fill((255, 255, 255))
    font, title_font = get_fonts()

    title = title_font.render(f"Polonaise Mode ({dice}D6)", True, (0, 0, 0))
    screen.blit(title, (width // 2 - title.get_width() // 2, 10))

    colors = get_colors()

    bar_width = min(80, (width - 100) // len(results))

    cell_height = 30
    scale_width = 40 if dice == 2 else 0
    start_x =  50 + scale_width
    start_y = 100

    p1_len   = 6
    p2_len   = 8
    p3_start = p1_len + p2_len

    if dice == 2:                                                   # show probability scale only in 2D6 mode
        draw_probability_scale(screen, 10, start_y, scale_width - 10, cell_height)

    for index, (bar_number, dice_roll, section) in enumerate(results):
        if index < p1_len:
            color_key = "polonaise_p1"
        elif index < p3_start:
            color_key = "polonaise_p2"
        else:
            color_key = "polonaise_p1"

        x = start_x + index * bar_width
        display_bar = bar_number[1:] if bar_number.startswith("R") else bar_number

        dict_key_base = f"polonoise_p{'1' if color_key == 'polonaise_p1' else '2'}"
        dict_key = f"{dict_key_base}_{dice}d"
        options = building_blocks[dict_key][display_bar]
        number_of_options = len(options)
        total_cell_height = number_of_options * cell_height

        for option_index, option in enumerate(options):
            y = start_y + option_index * cell_height

            if option == section:                           # highlight the chosen option
                pygame.draw.rect(screen, (50, 50, 50), (x, y, bar_width - 2, cell_height - 2), 2)
                pygame.draw.rect(screen, colors[color_key], (x + 2, y + 2, bar_width - 4, cell_height - 4))
            else:
                pygame.draw.rect(screen, colors[color_key], (x, y, bar_width - 2, cell_height - 2), 1)

            option_text = font.render(str(option), True, (0, 0, 0))
            screen.blit(option_text, (
                x + bar_width / 2 - option_text.get_width() / 2,
                y + cell_height / 2 - option_text.get_height() / 2)
            )

        # Print info below: bar number and dice roll
        bar_text  = font.render(f"Bar #{bar_number}", True, (0, 0, 0))
        dice_text = font.render(f"Dice: {dice_roll}", True, (0, 0, 0))
        text_y = start_y + total_cell_height + 5
        screen.blit(bar_text, (x + bar_width / 2 - bar_text.get_width() / 2, text_y))
        screen.blit(dice_text, (x + bar_width / 2 - dice_text.get_width() / 2, text_y + 20))

        # Print structure info
        if index == 0:
            part_text = title_font.render("Part 1", True, (0, 0, 0))
            screen.blit(part_text, (x, start_y - 40))
        elif index == p1_len:
            part_text = title_font.render("Part 2", True, (0, 0, 0))
            screen.blit(part_text, (x, start_y - 40))
        elif index == p3_start:
            part_text = title_font.render("Part 3 (Recap)", True, (0, 0, 0))
            screen.blit(part_text, (x, start_y - 40))


def visualize_minuet(screen, width, results, building_blocks):
    """
    Minuet visualization.
    """

    screen.fill((255, 255, 255))
    font, title_font = get_fonts()

    title = title_font.render("Minuet Mode", True, (0, 0, 0))
    screen.blit(title, (width // 2 - title.get_width() // 2, 10))

    colors = get_colors()

    bar_width   = min(40, (width - 100) // len(results))
    cell_height =  30
    start_x     =  50
    start_y     = 100

    menuet_part_length = 16
    trio_part_length   = 16

    for index, (bar_number, dice_roll, section) in enumerate(results):
        if index < menuet_part_length:                          # determine part: minuet A
            color_key = "menuet"
            options_dict = menuet_p1 if index < 8 else menuet_p2
        elif index < menuet_part_length + trio_part_length:     # determine part: trio
            color_key = "trio"
            options_dict = trio_p1 if index < menuet_part_length + 8 else trio_p2
        else:                                                   # determine part: minuet B
            color_key = "menuet"
            options_dict = menuet_p1 if index < menuet_part_length + trio_part_length + 8 else menuet_p2

        x = start_x + index * bar_width                         # calculate X position for text
        options = options_dict[bar_number]

        for option_index, option in enumerate(options):         # show all possible pointer options
            y = start_y + option_index * cell_height

            if option == section:                               # highlight the chosen option
                pygame.draw.rect(screen, (50, 50, 50), (x, y, bar_width - 2, cell_height - 2), 2)
                pygame.draw.rect(screen, colors[color_key], (x + 2, y + 2, bar_width - 4, cell_height - 4))
            else:
                pygame.draw.rect(screen, colors[color_key], (x, y, bar_width - 2, cell_height - 2), 1)

            option_text = font.render(str(option), True, (0, 0, 0))     # display number
            screen.blit(option_text, (
                x + bar_width / 2 - option_text.get_width() / 2, y + cell_height / 2 - option_text.get_height() / 2)
            )

        # Print info below: bar number and dice roll
        bar_text = font.render(f"{bar_number}", True, (0, 0, 0))
        dice_text = font.render(f"{dice_roll}", True, (255, 20, 20))
        screen.blit(bar_text, (x + bar_width / 2 - bar_text.get_width() / 2, start_y + 6 * cell_height + 5))
        screen.blit(dice_text, (x + bar_width / 2 - dice_text.get_width() / 2, start_y + 6 * cell_height + 25))

        # Print structure info
        if index == 0:
            section_text = title_font.render("M1", True, (0, 0, 0))
            screen.blit(section_text, (x, start_y - 40))
        elif index == 8:
            section_text = title_font.render("M2", True, (0, 0, 0))
            screen.blit(section_text, (x, start_y - 40))
        elif index == 16:
            section_text = title_font.render("T1", True, (0, 0, 0))
            screen.blit(section_text, (x, start_y - 40))
        elif index == 24:
            section_text = title_font.render("T2", True, (0, 0, 0))
            screen.blit(section_text, (x, start_y - 40))
        elif index == 32:
            section_text = title_font.render("M1 (Recap)", True, (0, 0, 0))
            screen.blit(section_text, (x, start_y - 40))
        elif index == 40:
            section_text = title_font.render("M2 (Recap)", True, (0, 0, 0))
            screen.blit(section_text, (x, start_y - 40))