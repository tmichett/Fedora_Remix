#!/usr/bin/env python3

import os
import subprocess
import shutil
import urllib.request
import sys
import pwd

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
    for package in packages:
        print(f"Installing {package}...")
        run_command(["dnf", "install", "-y", package])

def copy_directory(src, dest):
    """Copy a directory from source to destination"""
    print(f"Copying {src} to {dest}")
    if os.path.exists(src):
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
    else:
        print(f"Source directory {src} does not exist!")

def synchronize_files(src, dest):
    """Synchronize files using rsync"""
    print(f"Synchronizing {src} to {dest}")
    cmd = ["rsync", "-avz", src, dest]
    run_command(cmd)

def clone_git_repo(repo_url, dest):
    """Clone a git repository"""
    print(f"Cloning {repo_url} to {dest}")
    if os.path.exists(dest):
        print(f"Directory {dest} already exists, skipping git clone")
        return
    
    cmd = ["git", "clone", repo_url, dest]
    run_command(cmd)

def create_directory(path, mode=0o755):
    """Create a directory with specified permissions"""
    if not os.path.exists(path):
        print(f"Creating directory {path}")
        os.makedirs(path, mode=mode)
    else:
        print(f"Directory {path} already exists")

def download_file(url, dest):
    """Download a file from URL to destination"""
    print(f"Downloading {url} to {dest}")
    try:
        urllib.request.urlretrieve(url, dest)
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        sys.exit(1)

def enable_service(service_name):
    """Enable and start a system service"""
    print(f"Enabling and starting {service_name} service")
    run_command(["systemctl", "enable", service_name])
    run_command(["systemctl", "start", service_name])

def main():
    """Main function to setup system for Fedora Remix file hosting"""
    # Ensure we're running as root
    ensure_root()
    
    # Variables
    fedora_boot_files = ["vmlinuz", "initrd.img"]
    fedora_version = 40
    web_root = "/var/www/html"
    
    # Install required packages
    install_packages(["httpd"])
    
    # Create directories
    create_directory(web_root)
    
    # Copy files to web directory
    if os.path.exists("./files"):
        synchronize_files("./files/", f"{web_root}/")
    else:
        print("Warning: ./files directory not found")
    
    # Copy boot theme to web directory
    if os.path.exists("./files/boot/tm-fedora-remix"):
        synchronize_files("./files/boot/tm-fedora-remix/", f"{web_root}/")
    else:
        print("Warning: Boot theme directory not found")
    
    # Create Apache Configuration
    if os.path.exists("./files/httpd_index.conf"):
        synchronize_files("./files/httpd_index.conf", "/etc/httpd/conf.d/httpd_index.conf")
    else:
        print("Warning: httpd_index.conf file not found")
    
    # Clone Git repositories
    clone_git_repo("https://github.com/tmichett/FedoraRemixCustomize.git", f"{web_root}/FedoraRemixCustomize")
    clone_git_repo("https://github.com/tmichett/PXEServer.git", f"{web_root}/PXEServer")
    
    # Create PXE Boot Files directory
    create_directory(f"{web_root}/FedoraRemixPXE")
    
    # Download Boot Images for PXEBoot
    for file in fedora_boot_files:
        url = f"https://download.fedoraproject.org/pub/fedora/linux/releases/{fedora_version}/Server/x86_64/os/images/pxeboot/{file}"
        dest = f"{web_root}/FedoraRemixPXE/{file}"
        download_file(url, dest)
    
    # Synchronize scripts directory
    if os.path.exists("../YAD/scripts"):
        synchronize_files("../YAD/scripts/", f"{web_root}/scripts/")
    else:
        print("Warning: YAD scripts directory not found")
    
    # Copy YAD Files
    for item in ["Fedora_Remix_Apps.desktop", "Fedora_Remix_Customize.sh"]:
        src = f"../YAD/{item}"
        if os.path.exists(src):
            synchronize_files(src, f"{web_root}/{item}")
        else:
            print(f"Warning: {src} not found")
    
    # Copy VSCode Extensions
    if os.path.exists("files/VSCode"):
        synchronize_files("files/VSCode/", f"{web_root}/VSCode/")
    else:
        print("Warning: VSCode directory not found")
    
    # Copy UDP Cast
    if os.path.exists("files/udpcast-20230924-1.x86_64.rpm"):
        synchronize_files("files/udpcast-20230924-1.x86_64.rpm", f"{web_root}/udpcast-20230924-1.x86_64.rpm")
    else:
        print("Warning: UDP Cast RPM not found")
    
    # Copy Kickstart Python Fix
    if os.path.exists("files/Fixes/kickstart.py"):
        synchronize_files("files/Fixes/kickstart.py", f"{web_root}/kickstart.py")
    else:
        print("Warning: Kickstart Python fix not found")
    
    # Enable HTTPD Service
    enable_service("httpd")
    
    print("Setup complete!")

if __name__ == "__main__":
    main()