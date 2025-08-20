import numpy as np

def new_function():
    # This function generates a random 3x3 matrix and returns its determinant
    matrix = np.random.rand(3, 3)
    determinant = np.linalg.det(matrix)
    return determinant
