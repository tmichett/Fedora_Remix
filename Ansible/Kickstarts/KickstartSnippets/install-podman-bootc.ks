## Install Podman BootC from Repo (FIX ME - Not in Fedora Yet)
echo "Installing Podman BootC"
sudo dnf -y install 'dnf-command(copr)'
sudo dnf -y copr enable gmaglione/podman-bootc
sudo dnf -y install podman-bootc
