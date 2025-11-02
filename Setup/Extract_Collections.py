import subprocess

# Define output files
FILE_1 = "root_ansible_collections.txt"
FILE_2 = "python_ansible_collections.txt"
FILE_3 = "share_ansible_collections.txt"

# Function to extract collections based on the path
def extract_collections(file_path, path_to_match):
    with open(file_path, 'w') as file:
        file.write(f"Extracting collections from {path_to_match}...\n")

        # Run the ansible-galaxy collection list command
        result = subprocess.run(['ansible-galaxy', 'collection', 'list'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Check if the command was successful
        if result.returncode != 0:
            print(f"Error running ansible-galaxy collection list: {result.stderr.decode()}")
            return
        
        output = result.stdout.decode()

        # Flag to track when we are in the section of the path
        capturing = False

        # Split the output into lines and process each line
        for line in output.splitlines():
            # Check if the line matches the path to start capturing
            if path_to_match in line:
                capturing = True
                continue  # Skip the line that matched the path

            # Stop capturing if we reach a blank line
            if capturing and line.strip() == "":
                break

            # Capture collection names and versions only (lines that don't start with # or empty lines)
            if capturing and not line.startswith('#') and line.strip():
                # Split the line into words and capture the collection name and version
                columns = line.split()
                if len(columns) >= 2:
                    collection_name = columns[0]
                    version = columns[1]
                    file.write(f"{collection_name} {version}\n")
        
        file.write(f"Collections saved to {file_path}\n")

# Extract collections for each path
extract_collections(FILE_1, "/root/.ansible/collections/ansible_collections")
extract_collections(FILE_2, "/usr/local/lib/python3.13/site-packages/ansible_collections")
extract_collections(FILE_3, "/usr/share/ansible/collections/ansible_collections")

print("Extraction complete. Check the output files.")

