"""
Data Integrity Checker.
"""


import os


def check_files(base_path=""):
    checks = [
        ("midi_m", "mid",     96),          # folder, extension, number
        ("midi_p", "mid",    154),
        ("midi_t", "mid",     96),

        ("source_m", "mscz",  96),
        ("source_p", "mscz", 154),
        ("source_t", "mscz",  96),

        ("xml_m", "musicxml",  96),
        ("xml_p", "musicxml", 154),
        ("xml_t", "musicxml",  96),
    ]

    all_ok = True

    for folder, extension, count in checks:
        folder_path = os.path.join(base_path, folder)
        print(f"Currently checking folder '{folder_path}' ...", end="")
        folder_ok = True

        if not os.path.isdir(folder_path):
            print(f"\nERROR -- MISSING FOLDER: '{folder_path}'.")
            folder_ok = all_ok = False
            continue

        for file_number in range(1, count + 1):
            filename = f"{file_number}.{extension}"
            file_path = os.path.join(folder_path, filename)
            if not os.path.isfile(file_path):
                print(f"\nERROR -- MISSING FILE: '{file_path}'.")
                folder_ok = False
                all_ok = False

        if folder_ok:
            print(" okay")
    if all_ok:
        print("\nAll data is okay.")
    else:
        print("\nERROR: MISSING DATA!")


if __name__ == "__main__":
    check_files()