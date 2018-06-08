#!/bin/bash

# check to see if this has already been run
if lsmod | grep "nvidia" &> /dev/null ; then
  exit 0
fi

# stop and mask update engine
sudo systemctl stop update-engine
sudo systemctl mask update-engine

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
if ! [ grep "Accelerators" /etc/systemd/system/kubelet.service &> /dev/null ]; then
  awk '/cluster.local/ { print; print "  --feature-gates=\"Accelerators=true\" \\"; next }1' /etc/systemd/system/kubelet.service > /tmp/kubelet.service && sudo mv /tmp/kubelet.service /etc/systemd/system/kubelet.service
fi

# test nvidia-docker and also ensure the volume directory is populated
nvidia-docker run --rm nvidia/cuda nvidia-smi

# copy files if not already copied
if [ ! -d "/var/lib/nvidia-docker/volumes/nvidia_driver/384.59/lib64" ]; then
    sudo mkdir -p /var/lib/nvidia-docker/volumes/nvidia_driver/384.59/
    sudo cp -R /opt/bin /var/lib/nvidia-docker/volumes/nvidia_driver/384.59/
    sudo cp -R /opt/lib64 /var/lib/nvidia-docker/volumes/nvidia_driver/384.59/
    sudo ln -s /var/lib/nvidia-docker/volumes/nvidia_driver/384.59/lib64/ /var/lib/nvidia-docker/volumes/nvidia_driver/384.59/lib
fi

# restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
