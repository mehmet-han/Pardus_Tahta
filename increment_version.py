import os
import re

def increment_version():
    """Reads version.txt, increments the last number, and saves it back."""
    # Find the version.txt file in the client directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    version_file = os.path.join(script_dir, 'fatih_projesi_python', 'client', 'version.txt')
    
    if not os.path.exists(version_file):
        print(f"Error: {version_file} not found. Creating default.")
        with open(version_file, 'w', encoding='utf-8') as f:
            f.write("V1.00.01")
        print("Version set to V1.00.01")
        return
        
    with open(version_file, 'r', encoding='utf-8') as f:
        current_version = f.read().strip()
        
    # Match V1.00.01 -> prefix 'V1.00.', number '01'
    match = re.search(r'(V\d+\.\d+\.)(\d+)', current_version)
    if match:
        prefix = match.group(1)
        number_str = match.group(2)
        
        # Calculate new number with same padding
        width = len(number_str)
        new_number = int(number_str) + 1
        new_version = f"{prefix}{new_number:0{width}d}"
        
        # Save back
        with open(version_file, 'w', encoding='utf-8') as f:
            f.write(new_version)
            
        print(f"Version incremented: {current_version} -> {new_version}")
    else:
        print(f"Error: Could not parse version format '{current_version}'.")
        print("Expected format like V1.00.01")

if __name__ == "__main__":
    increment_version()
