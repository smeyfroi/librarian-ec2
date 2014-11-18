#!/bin/bash
#This script installs chef omnibus
#Run this script on a new EC2 instance as the user-data script, which is run by `root` on machine startup.
set -e -x

export DEBIAN_FRONTEND=noninteractive

apt-get update

curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v 11.16
