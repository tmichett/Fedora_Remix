## Create FedoraRemix Custom Tools (LMStudio) ##
echo "Downloading LMStudio AppImage"
mkdir /opt/FedoraRemixApps
cd /opt/FedoraRemixApps
wget https://installers.lmstudio.ai/linux/x64/0.3.14-5/LM-Studio-0.3.14-5-x64.AppImage
chmod +x /opt/FedoraRemixApps/LM-Studio-0.3.14-5-x64.AppImage

## Create Desktop Icon for LMStudio
echo "Installing LMStudio Icons"
cd /usr/share/applications
wget  http://localhost/files/LMStudio.desktop

## Load Icons for Custom Applications
cd /usr/share/icons
wget http://localhost/files/logos/fedora_tools_logo.png
wget http://localhost/files/logos/lmstudio.png
