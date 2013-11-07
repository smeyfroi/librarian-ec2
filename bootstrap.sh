#!/bin/bash
#This script installs ruby, rubygems, and chef
#Run this script on a new EC2 instance as the user-data script, which is run by `root` on machine startup.
set -e -x

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get --no-install-recommends -y install build-essential ruby1.9.1-full libopenssl-ruby git-core

curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v 11.6.0
/opt/chef/embedded/bin/gem install --no-rdoc --no-ri librarian-chef --version=0.0.1
