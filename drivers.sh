DRIVER=535.54.03

apt-get update
apt-get -y install sudo
sudo yum install gcc10 -y
sudo wget -O /tmp/NVIDIA-Linux-driver.run "https://us.download.nvidia.com/tesla/${DRIVER}/NVIDIA-Linux-x86_64-${DRIVER}.run"
sudo CC=gcc10-cc sh /tmp/NVIDIA-Linux-driver.run -q -a --ui=none
