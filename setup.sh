#!/bin/bash
#This script uploads everything required for `chef-solo` to run
set -e

if test -z "$3"
then
  echo "I need 
1) IP address of a machine to provision
2) Path to a Vagrant VM folder (a folder containing a Vagrantfile) that you want me to extract Chef recipes from
3) Path to a SSH private key for this machine"
  exit 1
fi

#Run vagrant to create dna.json
echo "Making dna.json"
eval "cd \"$2\" && \
      vagrant > /dev/null || true && \
      cd -"

#Try to match and extract a port provided to the script
ADDR=$1
IP=${ADDR%:*}
PORT=${ADDR#*:}
if [ "$IP" == "$PORT" ] ; then
    PORT=22
fi

USERNAME=ubuntu
DNA=$2/dna.json

EC2_SSH_PRIVATE_KEY=$3

#make sure this matches the CHEF_FILE_CACHE_PATH in `bootstrap.sh`
CHEF_FILE_CACHE_PATH=/tmp/cheftime
CHEF_COOKBOOK_PATH=/tmp/cheftime/cookbooks

#Upload Chefile and dna.json to directory (need to use sudo to copy over to $CHEF_FILE_CACHE_PATH and run chef)
echo "Uploading dna.json"
scp -q -i $EC2_SSH_PRIVATE_KEY -r -P $PORT \
  $DNA \
  $USERNAME@$IP:.

# Upload a berks package of all our cookbooks
echo "Uploading cookbooks"
berks package /tmp/cookbooks.tgz
scp -q -i $EC2_SSH_PRIVATE_KEY -r -P $PORT \
  /tmp/cookbooks.tgz \
  $USERNAME@$IP:.

#check to see if the bootstrap script has completed running
echo "Check requirements chef-solo"
MAX_TESTS=10
SLEEP_BETWEEN_TESTS=30

OVER=0
TESTS=0
while [ $OVER != 1 ] && [ $TESTS -lt $MAX_TESTS ]; do
  echo "Testing for installation of chef-solo"
  (ssh -q -t -p "$PORT" -o "StrictHostKeyChecking no" \
    -i $EC2_SSH_PRIVATE_KEY \
    $USERNAME@$IP \
    "ls /opt/chef/bin/chef-solo > /dev/null")
  if [ "$?" -ne "0" ] ; then
    TESTS=$(echo $TESTS+1 | bc)
    sleep $SLEEP_BETWEEN_TESTS
  else
    OVER=1
  fi
done
if [ $TESTS = $MAX_TESTS ]; then
    echo "${IP} never got chef-solo installed" 1>&2
    exit 1
fi
echo "$IP has chef-solo installed"

echo "Run chef-solo, this can take a while"

echo "file_cache_path \"$CHEF_FILE_CACHE_PATH\"
  cookbook_path [\"$CHEF_COOKBOOK_PATH\"]
  role_path []
  log_level :info" > /tmp/solo.rb

scp -q -i $EC2_SSH_PRIVATE_KEY -r -P $PORT \
  /tmp/solo.rb \
  $USERNAME@$IP:.

eval "ssh -q -t -p \"$PORT\" -o \"StrictHostKeyChecking no\" -l \"$USERNAME\" -i \"$EC2_SSH_PRIVATE_KEY\" $USERNAME@$IP \"sudo -i sh -c ' \
  mkdir -p $CHEF_FILE_CACHE_PATH \
'\""

eval "ssh -q -t -p \"$PORT\" -o \"StrictHostKeyChecking no\" -l \"$USERNAME\" -i \"$EC2_SSH_PRIVATE_KEY\" $USERNAME@$IP \"sudo -i sh -c 'cd $CHEF_FILE_CACHE_PATH && \
mkdir -p /root/.ssh && \
cp /home/ubuntu/.ssh/id_rsa /root/.ssh/id_rsa && \
chmod 600 /root/.ssh/id_rsa && \
chown root:root /root/.ssh/id_rsa && \
cp /home/$USERNAME/dna.json . && \
cp /home/$USERNAME/solo.rb . && \
cp /home/$USERNAME/cookbooks.tgz . && \
tar xzf cookbooks.tgz && \
/opt/chef/bin/chef-solo -c $CHEF_FILE_CACHE_PATH/solo.rb -j dna.json'\""

echo "Done!"
