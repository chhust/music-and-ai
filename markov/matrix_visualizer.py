"""
I used the following literature:

- Jake VanderPlas, "Python Data Science Handbook: Essential Tools for Working with Data," Sebastopol: O'Reilly, 2017.

- Wes MacKinney, "Datenanalyse mit Python: Auswertung von Daten mit pandas, NumPy und Jupyter,"
                  Heidelberg: O'Reilly, 2023.
"""


import matplotlib.pyplot as plt


class MatrixVisualizer():
    """
    This class displays the adjacency matrix both as text output and as a heatmap.
    """


    def __init__(self, matrix_data, matrix_name):
        """
        Init values.
        """

        self.matrix_data = matrix_data
        self.matrix_name = matrix_name


    def display_text(self):
        """
        Show the adjacency matrix as text.
        """

        print(f"\nDisplaying data for\n'{self.matrix_name.title()}':\n")

        for row in self.matrix_data:
            print(" ".join(f"{element:>3}" for element in row))
        print("\n")


    def display_heatmap(self):
        """
        Display matrix values as a heatmap.
        """

        # Initialize the output and begin creating the heatmap.
        # im[age]show of data with "color map," interpolation="nearest" creates pixelated output.
        plt.figure(figsize=(10, 8))
        plt.imshow(self.matrix_data, cmap="Oranges", interpolation="nearest")
        plt.colorbar()

        # Annotate cells with the values: iterate rows and columns,
        # print correct value at col/row coordinates, center vertically and horizontally
        for row_index, row in enumerate(self.matrix_data):
            for column_index, value in enumerate(row):
                plt.text(column_index, row_index, f"{value:.2f}", ha="center", va="center", color="black")

        plt.title(f"Heatmap for {self.matrix_name.title()}")
        plt.xticks(range(len(self.matrix_data[0])))
        plt.yticks(range(len(self.matrix_data)))

        plt.show()


    def visualize_adjacency_matrix(self):
        """
        Visualize the adjacency matrix: display both as text and heatmap.
        """

        self.display_text()
        self.display_heatmap()