#!/bin/bash

# pull down and unzip coreos-nvidia PR that includes install scripts and other changes
wget https://github.com/Clarifai/coreos-nvidia/archive/c2fec9021dc5394f22f3be24ffbcaed7a17b0826.zip
unzip c2fec9021dc5394f22f3be24ffbcaed7a17b0826.zip
cd coreos-nvidia-c2fec9021dc5394f22f3be24ffbcaed7a17b0826/

# build for recent nvidia driver and relevant coreos version
./build.sh 384.59 stable 1465.7.0

# fix check for coreos name in uname result
sed -i -e 's/-coreos-/coreos/g' nvidia_install.sh
sed -i -e 's/-coreos-/coreos/g' nvidia_docker_install.sh

# update entries in install script
sed -i -e 's/beta/stable/g' nvidia_install.sh
sed -i -e 's/1185.5.0/1465.7.0/g' nvidia_install.sh
sed -i -e 's/375.20/384.59/g' nvidia_install.sh

# run install and docker install
sudo ./nvidia_install.sh
sudo ./nvidia_docker_install.sh

# add feature-gates to kubelet service
awk '/cluster.local/ { print; print "  --feature-gates=\"Accelerators=true\" \\"; next }1' /etc/systemd/system/kubelet.service > /tmp/kubelet.service && sudo mv /tmp/kubelet.service /etc/systemd/system/kubelet.service

# restart kubelet?
# sudo systemctl restart kubelet
