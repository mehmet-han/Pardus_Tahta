from setuptools import setup
from Cython.Build import cythonize
import os

# We only compile the main client file and any other sensitive Python files
# into C extensions.

extensions = [
    "fatih_projesi_python/client/client.py"
]

setup(
    ext_modules=cythonize(
        extensions,
        compiler_directives={'language_level': "3"}
    )
)
