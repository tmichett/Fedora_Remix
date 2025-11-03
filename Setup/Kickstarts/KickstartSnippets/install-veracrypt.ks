## Install VeraCrypt
echo "Installing VeraCrypt"
dnf install -y https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.20/veracrypt-1.26.20-Fedora-40-x86_64.rpm
cd /usr/share/applications
wget http://localhost/files/logos/veracrypt.png
sed -i 's/Icon=veracrypt/Icon=\/usr\/share\/applications\/veracrypt.png/g' /usr/share/applications/veracrypt.desktop
