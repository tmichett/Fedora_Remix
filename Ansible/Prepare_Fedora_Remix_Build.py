#!/usr/bin/env python3

import os
import subprocess
import shutil
import sys

def run_command(command, shell=False):
    """Run a shell command and return the output"""
    print(f"Running command: {command}")
    try:
        if shell:
            result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        else:
            result = subprocess.run(command, check=True, text=True, capture_output=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        print(f"Command output: {e.stdout}")
        print(f"Error output: {e.stderr}")
        sys.exit(1)

def is_root():
    """Check if the script is running as root"""
    return os.geteuid() == 0

def ensure_root():
    """Ensure the script is running as root"""
    if not is_root():
        print("This script must be run as root. Please use sudo.")
        sys.exit(1)

def install_packages(packages):
    """Install packages using dnf/yum"""
    print(f"Installing packages: {', '.join(packages)}")
    run_command(["dnf", "install", "-y"] + packages)

def create_directory(path, mode=0o755):
    """Create a directory with specified permissions"""
    if not os.path.exists(path):
        print(f"Creating directory {path}")
        os.makedirs(path, mode=mode)
    else:
        print(f"Directory {path} already exists")

def synchronize_files(src, dest):
    """Synchronize files using rsync with sudo"""
    print(f"Synchronizing {src} to {dest}")
    if not os.path.exists(src):
        print(f"Warning: Source directory {src} does not exist")
        return
    
    cmd = ["sudo", "rsync", "-avz", src, dest]
    run_command(cmd)

def copy_file(src, dest, mode=None):
    """Copy a file from source to destination with optional permissions"""
    print(f"Copying {src} to {dest}")
    if not os.path.exists(src):
        print(f"Warning: Source file {src} does not exist")
        return
        
    # Create destination directory if needed
    dest_dir = os.path.dirname(dest)
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
        
    shutil.copy2(src, dest)
    
    # Set file permissions if specified
    if mode is not None:
        os.chmod(dest, mode)

def main():
    """Main function to setup system for Fedora Remix creation and building"""
    # Ensure we're running as root
    ensure_root()
    
    # Variables
    remix_packages = ["vim", "livecd-tools", "sshfs"]
    remix_directories = [
        "/livecd-creator/FedoraRemix",
        "/livecd-creator/package-cache"
    ]
    
    # Install required packages
    install_packages(remix_packages)
    
    # Create directories
    for directory in remix_directories:
        create_directory(directory)
    
    # Copy Kickstart files
    kickstart_src = "./Kickstarts/"
    if os.path.exists(kickstart_src):
        synchronize_files(kickstart_src, "/livecd-creator/FedoraRemix/")
    else:
        print(f"Warning: Kickstarts directory not found at {kickstart_src}")
    
    # Copy Build Script Playbook
    copy_file("./Prepare_Fedora_Remix_Build.yml", "/livecd-creator/FedoraRemix/Prepare_Fedora_Remix_Build.yml")
    
    # Copy Build Scripts with executable permissions
    # Calculate the mode for u+rwx,g+x,o+x (0755 in octal)
    exec_mode = 0o755
    copy_file("../Remix_Buid_Script.sh", "/livecd-creator/FedoraRemix/Remix_Buid_Script.sh", exec_mode)
    copy_file("../Enhanced_Remix_Build_Script.sh", "/livecd-creator/FedoraRemix/Enhanced_Remix_Build_Script.sh", exec_mode)
    
    # Copy formatting demo script with executable permissions
    copy_file("../format-demo.sh", "/livecd-creator/FedoraRemix/format-demo.sh", exec_mode)
    
    print("Setup complete!")
    print("Available build scripts:")
    print("  - Remix_Buid_Script.sh (Original)")
    print("  - Enhanced_Remix_Build_Script.sh (Recommended - Rich formatting)")
    print("  - format-demo.sh (Formatting demonstration)")

if __name__ == "__main__":
    main()