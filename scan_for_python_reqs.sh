#!/bin/bash

# Check if the right number of arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: ./scan_for_python_reqs.sh <directory_path>"
    exit 1
fi

# Parameters
DIRECTORY=$1

# Identify the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Identify the first venv* directory in the script's directory
VENV_PATH=$(find "$SCRIPT_DIR" -type d -name "venv*" | head -n 1)

# Check if we found a venv* directory
if [ -z "$VENV_PATH" ]; then
    echo "No venv* directory found in the script's directory."
    exit 1
fi

# Use the Python binary from the virtual environment to check modules
$VENV_PATH/bin/python <<END

import stdlib_list
import os
import ast

def extract_imports_from_file(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        node = ast.parse(f.read(), file_path)
        imports = []
        for n in ast.walk(node):
            if isinstance(n, ast.Import):
                imports.extend([alias.name.split('.')[0] for alias in n.names])
            elif isinstance(n, ast.ImportFrom):
                if n.module:
                    imports.append(n.module.split('.')[0])
                else:
                    # Handling relative imports
                    for alias in n.names:
                        imports.append(alias.name.split('.')[0])
        return imports

def is_standard_module(module_name, libs):
    return module_name in libs

# Get the list of all standard libraries for the Python version of the virtual environment
standard_libs = stdlib_list.stdlib_list()

non_standard_imports = set()

# Walk through the directory and search for all .py files
for root, dirs, files in os.walk("$DIRECTORY"):
    for file in files:
        if file.endswith(".py"):
            file_path = os.path.join(root, file)
            imports = extract_imports_from_file(file_path)
            for imp in imports:
                if not is_standard_module(imp, standard_libs):
                    non_standard_imports.add(imp)

for imp in sorted(non_standard_imports):
    print(imp)

# Save the requirements.txt in the SCRIPT_DIR directory
with open(os.path.join("$SCRIPT_DIR", 'requirements.txt'), 'w') as f:
    for imp in sorted(non_standard_imports):
        f.write(f"{imp}\n")

END
