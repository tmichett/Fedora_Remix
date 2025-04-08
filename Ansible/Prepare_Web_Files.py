#!/usr/bin/env python3

import os
import subprocess
import shutil
import urllib.request
import sys

def run_command(command, shell=False):
    """Run a shell command and return the output"""
    cmd_str = ' '.join(command) if isinstance(command, list) else command
    print(f"Running command: {cmd_str}")
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
    if isinstance(packages, str):
        packages = [packages]
    print(f"Installing packages: {', '.join(packages)}")
    run_command(["dnf", "install", "-y"] + packages)

def create_directory(path, mode=0o755):
    """Create a directory with specified permissions"""
    if not os.path.exists(path):
        print(f"Creating directory {path}")
        os.makedirs(path, mode=mode)
    else:
        print(f"Directory {path} already exists")

def rsync(src, dest):
    """Use rsync to copy files as Ansible's synchronize module would"""
    if not os.path.exists(src):
        print(f"Error: Source path {src} does not exist")
        return False
        
    print(f"Running rsync from {src} to {dest}")
    # -a: archive mode (preserves permissions, etc.)
    # -v: verbose
    cmd = ["rsync", "-av", src, dest]
    run_command(cmd)
    return True

def clone_git_repo(repo_url, dest):
    """Clone a git repository"""
    print(f"Cloning {repo_url} to {dest}")
    parent_dir = os.path.dirname(dest)
    if not os.path.exists(parent_dir):
        create_directory(parent_dir)
        
    if os.path.exists(dest):
        print(f"Directory {dest} already exists, updating repository...")
        current_dir = os.getcwd()
        try:
            os.chdir(dest)
            run_command(["git", "pull"])
        finally:
            os.chdir(current_dir)
        return
    
    cmd = ["git", "clone", repo_url, dest]
    run_command(cmd)

def download_file(url, dest):
    """Download a file from URL to destination"""
    print(f"Downloading {url} to {dest}")
    try:
        parent_dir = os.path.dirname(dest)
        if not os.path.exists(parent_dir):
            create_directory(parent_dir)
            
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
    install_packages("httpd")
    
    # Create web directory
    create_directory(web_root)
    
    # Copy Files to Web Directory 
    # This should create /var/www/html/files/
    if os.path.exists("./files"):
        rsync("./files", f"{web_root}/")
    else:
        print(f"Warning: ./files directory not found")
    
    # Copy Boot Theme to Web Directory
    # This should create /var/www/html/tm-fedora-remix/
    boot_theme_path = "./files/boot/tm-fedora-remix"
    if os.path.exists(boot_theme_path):
        rsync(boot_theme_path, f"{web_root}/")
    else:
        print(f"Warning: {boot_theme_path} not found")
    
    # Create Apache Configuration
    apache_conf = "./files/httpd_index.conf"
    if os.path.exists(apache_conf):
        create_directory("/etc/httpd/conf.d")
        rsync(apache_conf, "/etc/httpd/conf.d/")
    else:
        print(f"Warning: {apache_conf} file not found")
    
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
    
    # Create and Synchronize Scripts Directory
    scripts_dir = "../YAD/scripts"
    if os.path.exists(scripts_dir):
        rsync(scripts_dir, f"{web_root}/")
    else:
        print(f"Warning: {scripts_dir} directory not found")
    
    # Copy YAD Files
    for item in ["Fedora_Remix_Apps.desktop", "Fedora_Remix_Customize.sh"]:
        src = f"../YAD/{item}"
        if os.path.exists(src):
            rsync(src, f"{web_root}/")
        else:
            print(f"Warning: {src} not found")
    
    # Copy VSCode Extensions
    vscode_dir = "files/VSCode"
    if os.path.exists(vscode_dir):
        rsync(vscode_dir, f"{web_root}/")
    else:
        print(f"Warning: {vscode_dir} directory not found")
    
    # Copy UDP Cast
    udpcast_file = "files/udpcast-20230924-1.x86_64.rpm"
    if os.path.exists(udpcast_file):
        rsync(udpcast_file, f"{web_root}/")
    else:
        print(f"Warning: {udpcast_file} not found")
    
    # Copy Kickstart Python Fix
    kickstart_file = "files/Fixes/kickstart.py"
    if os.path.exists(kickstart_file):
        rsync(kickstart_file, f"{web_root}/")
    else:
        print(f"Warning: {kickstart_file} not found")
    
    # Enable HTTPD Service
    enable_service("httpd")
    
    print("Setup complete!")

if __name__ == "__main__":
    main()