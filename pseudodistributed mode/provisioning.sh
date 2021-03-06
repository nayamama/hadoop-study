#!/usr/bin/env bash

set -x
set -e

function ip_config(){
  # removed hostname line generated by vagrant
  sudo echo "Configuring /etc/hosts ..."
  sudo echo "127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4 " > /etc/hosts
  sudo echo "::1       localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
}

function add_hadoop_user(){
  echo "$(whoami)"
  echo "$(pwd)"
  
  [[ $(sudo cat /etc/passwd | sudo grep hadoop) ]] && sudo userdel -r hadoop
  sudo useradd hadoop
  sudo echo "hadoop:hadoop" | sudo chpasswd
  sudo gpasswd -a hadoop wheel
  # sudo su
  # cd /etc/sudoers 
  # visudo
  echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 
  
  # user add validation
  [[ $(tail -1 /etc/passwd) == *hadoop* ]] && echo -e "[$(date +"%c")] \e[32mINFO: user hadoop added succesfully\e[0m" >> /home/hadoop/hadoop_install.log || echo "[$(date +"%c")] \e[31mERR: Fail to add user hadoop\e[0m" >> /home/hadoop/hadoop_install.log
  
  # su - hadoop
  
  # pwd change validation
  #[[ $(whoami) == *hadoop* ]] && echo "[$(date)] \e[32mINFO: User is set to $USER\e[0m" >> /home/hadoop/hadoop_install.log || exit 1
  # echo "[$(date)] \e[31mERR: Fail to set user $USER to hadoop\e[0m" >> /home/hadoop/hadoop_install.log
}


function install_java(){
  echo "Install Java"
  sudo yum -y install java-1.8.0-openjdk
  sudo yum -y install java-1.8.0-openjdk-devel
  echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64" >> /home/hadoop/.bashrc
  echo "export JRE_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64/jre" >> /home/hadoop/.bashrc
  source /home/hadoop/.bashrc
  
  # java install validation
  [[ $(which java) ]] && echo -e "[$(date +"%c")] \e[32mINFO: Java install complete\e[0m" >> /home/hadoop/hadoop_install.log || echo -e "[$(date +"%c")] \e[31mERR: Fail to install java\e[0m" >> /home/hadoop/hadoop_install.log 
  
  # java environment variables validation
  [[ ! -z "${JAVA_HOME}" ]] && echo -e "[$(date +"%c")] \e[32mIINFO: JAVA_HOME is set\e[0m" >> /home/hadoop/hadoop_install.log || echo -e "[$(date +"%c")] \e[31mERR: $JAVA_HOME is not set\e[0m" >> /home/hadoop/hadoop_install.log
  [[ ! -z "${JRE_HOME}" ]] && echo -e "[$(date +"%c")] \e[32mIINFO: JRE_HOME is set\e[0m" >> /home/hadoop/hadoop_install.log || echo -e "[$(date +"%c")] \e[31mERR: $JRE_HOME is not set\e[0m" >> /home/hadoop/hadoop_install.log
}


function install_hadoop(){
  echo "Install Hadoop"
  #sudo yum -y install wget
  sudo wget https://www.apache.org/dist/hadoop/core/stable2/hadoop-2.9.1.tar.gz -O /usr/etc/hadoop-2.9.1.tar.gz
  cd /usr/etc/
  sudo tar -xvf /usr/etc/hadoop-2.9.1.tar.gz
  sudo rm -rf hadoop-2.9.1.tar.gz
  #sudo  cp hadoop-2.9.1.tar.gz /usr/etc/ 
  
  
  #cd ~
  echo "export HADOOP_PREFIX=/usr/etc/hadoop-2.9.1" >> /home/hadoop/.bashrc
  echo "export HADOOP_HOME=/usr/etc/hadoop-2.9.1" >> /home/hadoop/.bashrc
  echo "export HADOOP_COMMON_HOME=/usr/etc/hadoop-2.9.1" >> /home/hadoop/.bashrc
  echo "export HADOOP_HDFS_HOME=/usr/etc/hadoop-2.9.1" >> /home/hadoop/.bashrc
  echo "export HADOOP_MAPRED_HOME=/usr/etc/hadoop-2.9.1" >> /home/hadoop/.bashrc
  echo "export HADOOP_YARN_HOME=/usr/etc/hadoop-2.9.1" >> /home/hadoop/.bashrc
  echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop-config" >> /home/hadoop/.bashrc
  echo "export PATH=$PATH:/usr/etc/hadoop-2.9.1/sbin:/usr/etc/hadoop-2.9.1/bin:$JAVA_HOME/bin:$JRE_HOME/bin" >> /home/hadoop/.bashrc
  source /home/hadoop/.bashrc
  
  #can not find hadoop under root user
   #[[ $(sudo -u hadoop which hadoop) ]] && echo -e "[$(date +"%c")] \e[32mIINFO: Hadoop install complete\e[0m" >> /home/hadoop/hadoop_install.log || echo -e "[$(date +"%c")] \e[31mERR: Fail to install Hadoop\e[0m" >> /home/hadoop/hadoop_install.log
   
   [[ ! -z "${HADOOP_PREFIX}" ]] && echo -e "[$(date +"%c")] \e[32mIINFO: HADOOP_HOME is set\e[0m" >> /home/hadoop/hadoop_install.log || echo -e "[$(date +"%c")] \e[31mERR: $HADOOP_HOME is not set\e[0m" >> /home/hadoop/hadoop_install.log
  
}

  
function config_hadoop(){
   cd /home/hadoop
   
   # pull and untar config files
   wget --no-check-certificate https://sqroot-portal.sqroot.local/download_depot/lab_dev/hadoop-config.tar.gz -O /home/hadoop/hadoop-config.tar.gz
   tar -xvf /home/hadoop/hadoop-config.tar.gz
   rm -rf hadoop-config.tar.gz
   sudo chown -R hadoop:hadoop /home/hadoop/hadoop-config
   
   # config SSH
   sudo -u hadoop ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa
   sudo -u hadoop cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
   sudo chown hadoop:hadoop /home/hadoop/.ssh/authorized_keys
   sudo chown hadoop:hadoop /home/hadoop/.ssh/id_rsa
   sudo chmod 600 /home/hadoop/.ssh/authorized_keys
   sudo chmod 600 /home/hadoop/.ssh/id_rsa
   
   # fix bug for hadoop native lib
   cd /usr/lib64
   sudo ln -s libcrypto.so.1.0.2k libcrypto.so
   
   # prepare folders for hadoop
   mkdir -p /home/hadoop/hadoop_data
   mkdir -p /home/hadoop/hadoop_namenode
   sudo chown hadoop:hadoop /home/hadoop/hadoop_data
   sudo chown hadoop:hadoop /home/hadoop/hadoop_namenode
   
   # make logs dir
   # mkdir /usr/etc/hadoop-2.9.1/logs
   sudo chown -R hadoop:hadoop /usr/etc/hadoop-2.9.1
   
   # format the HDFS filesystem
   # sudo -u hadoop hadoop namenode -format
 }


ip_config
add_hadoop_user
install_java
install_hadoop
config_hadoop

echo "DONE"

# nohup nice -n $YARN_NICENESS "$HADOOP_YARN_HOME"/bin/yarn --config $YARN_CONF_DIR $command "$@" > "$log" 2>&1 < /dev/null &
