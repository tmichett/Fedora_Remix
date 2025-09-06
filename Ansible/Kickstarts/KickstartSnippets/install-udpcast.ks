## Install UDP Cast 
echo "Installing UDPCast"
mkdir -p /opt/udpcast
cd /opt/udpcast
wget http://localhost/udpcast-20230924-1.x86_64.rpm
dnf install -y ./udpcast-20230924-1.x86_64.rpm
