#!/bin/bash
echo "Fixing the Python Kickstart Program"
sudo sh -c 'sudo cp /opt/FedoraRemix/kickstart.py /usr/lib/python3.13/site-packages/imgcreate/kickstart.py'
sudo sh -c 'chmod +x /usr/lib/python3.13/site-packages/imgcreate/kickstart.py'
echo "Finished Copying and Fixing the Kickstart Program"