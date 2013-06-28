#!/bin/bash
#This script installs ruby, rubygems, and chef
#Run this script on a new EC2 instance as the user-data script, which is run by `root` on machine startup.
set -e -x

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get --no-install-recommends -y install build-essential ruby1.9.1-full libopenssl-ruby git-core

gem install --no-rdoc --no-ri chef --version=11.4.2
gem install --no-rdoc --no-ri librarian-chef --version=0.0.1

echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/lib/gems/1.8/bin"' > /etc/environment
