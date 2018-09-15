#!/usr/bin/bash

# install dependencies
sudo yum -y groupinstall "Development Tools"
sudo yum -y install gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel

# dowload git
cd /usr/etc/
wget https://github.com/git/git/archive/v2.19.0.tar.gz -O git.tar.gz
tar -zxf git.tar.gz
rm -rf git.tar.gz
cd git-*
make configure
./configure --prefix=/usr/local

# check
[[ $(which git) ]] && echo "Git installation complete" || echo "************* Fail to install Git *******************"

# configure
git config --global user.name "Qi Yang"
git config --global user.email "nayamama@hotmail.com"
[[ $(git config --list | head -n 1) == *"Qi Yang"* && $(git config --list | head -n 2) == *"nayamama"* ]] && echo "git configuration complete" || echo "************ Please check git configration ************************"