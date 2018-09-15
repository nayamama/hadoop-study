#!/usr/bin/bash

# download and install java
sudo yum install -y java-1.8.0-openjdk-devel
sleep 5

[[ $(which java) ]] && echo "java installed"

# download maven binaries
cd /usr/local/src
wget https://archive.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar -xf apache-maven-3.5.2-bin.tar.gz
rm -f apache-maven-3.5.2-bin.tar.gz
mv apache-maven-3.5.2/ apache-maven/

# config maven environment
cd /etc/profile.d/
if [ -f maven.sh ]; then
  rm -rf maven.sh;
fi
touch maven.sh
echo "export M2_HOME=/usr/local/src/apache-maven
export PATH=$M2_HOME/bin:$PATH >> maven.sh

chmod +x maven.sh
source /etc/profile.d/maven.sh

[[ $(which mvn) ]] && echo "maven installation complete" || echo "************* Fail to install maven *******************"