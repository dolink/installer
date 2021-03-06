#!/bin/bash

# Run this script as root ie:
# wget -O - https://raw.githubusercontent.com/dolink/installer/master/install.sh | sudo bash

set -e

bold=`tput bold`;
normal=`tput sgr0`;
space_left=`df | grep /dev/root | awk '{print $3}'`;
username=`users | awk '{print $1}'`;

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ ${space_left} -lt 100000 ]]
then
	echo "${bold} In order to install the ollo software, you must have at least 100 megs of free space. Try running raspi-config and using the \"expand_rootfs\" option to free up some space ${normal}"
	exit 1
fi


# Updating apt-get
echo -e "\n→ ${bold}Updating apt-get${normal}\n";
sudo apt-get update; # > /dev/null;

echo -e "\n→ ${bold}Installing python-software-properties${normal}\n";
sudo apt-get -qq -y -f -m install python-software-properties; # > /dev/null;

echo -e "\n→ ${bold}Installing ntpdate${normal}\n";
sudo apt-get -qq -y -f -m install ntpdate; # > /dev/null;
sudo /etc/init.d/ntp stop

# Add NTP Update as a daily cron job
echo -e "\n→ ${bold}Create the ntpdate file${normal}\n";
sudo touch /etc/cron.daily/ntpdate;
echo -e "\n→ ${bold}Add ntpdate ntp.ubuntu.com${normal}\n";
sudo echo "ntpdate ntp.ubuntu.com" > /etc/cron.daily/ntpdate;
echo -e "\n→ ${bold}Making ntpdate executable${normal}\n";
sudo chmod 755 /etc/cron.daily/ntpdate;

# Update the timedate
echo -e "\n→ ${bold}Updating the time${normal}\n";
sudo ntpdate ntp.ubuntu.com pool.ntp.org;
sudo /etc/init.d/ntp start

###################################################################
# Download and install the Essential packages
###################################################################

echo -e "\n→ ${bold}Installing avahi-daemon${normal}\n";
sudo apt-get -qq -y -f -m  install avahi-daemon; # > /dev/null;

echo -e "\n→ ${bold}Installing upstart${normal}\n";
echo 'Yes, do as I say!' | sudo apt-get -o DPkg::options=--force-remove-essential -y --force-yes install upstart; # > /dev/null;

# Download and install the Essential packages.
echo -e "\n→ ${bold}Installing git${normal}\n";
sudo apt-get -qq -y -f -m  install git; # > /dev/null;

echo -e "\n→ ${bold}Installing ruby1.9.1-dev${normal}\n";
sudo apt-get -qq -y -f -m  install ruby1.9.1-dev; # > /dev/null;

echo -e "\n→ ${bold}Installing avrdude${normal}\n";
sudo apt-get -qq -y -f -m  install avrdude; # > /dev/null;

echo -e "\n→ ${bold}Installing psmisc${normal}\n";
sudo apt-get -qq -y -f -m  install psmisc; # > /dev/null;

echo -e "\n→ ${bold}Installing curl${normal}\n";
sudo apt-get -qq -y -f -m  install curl; # > /dev/null;

echo -e "\n→ ${bold}Using source http://rubygems.org for rubygems${normal}\n";
sudo gem sources -r https://rubygems.org
sudo gem sources -r http://rubygems.org
sudo gem sources -a http://rubygems.org

# Install Sinatra
echo -e "\n→ ${bold}Installing the sinatra gem${normal}\n";
sudo gem install sinatra  --verbose --no-rdoc --no-ri; # > /dev/null;

# Install getifaddrs
echo -e "\n→ ${bold}Installing the getifaddrs gem${normal}\n";
sudo gem install system-getifaddrs  --verbose --no-rdoc --no-ri; # > /dev/null;

# Install gpac
echo -e "\n→ ${bold}Installing gpac${normal}\n";
sudo apt-get -qq -y -f -m install gpac; # > /dev/null;

echo -e "\n→ ${bold}Installing node & npm${normal}\n";
# curl -sL https://deb.nodesource.com/setup_0.12 | bash -
# sudo apt-get update; # > /dev/null;
# sudo apt-get -qq -y -f -m  install nodejs; # > /dev/null;

wget http://conoroneill.net.s3.amazonaws.com/wp-content/uploads/2015/09/node-v0.12.7-linux-arm-v6.tar.gz
cd /usr/local
sudo tar xzvf ~/node-v0.12.7-linux-arm-v6.tar.gz --strip=1

# cd /tmp
# rm -f node_latest_armhf.*
# wget http://node-arm.herokuapp.com/node_latest_armhf.deb
# sudo dpkg -i node_latest_armhf.deb > /dev/null;
# rm -f node_latest_armhf.*

echo -e "\n→ ${bold}Installing wiring-pi${normal}\n";
cd /tmp
rm -fr wiringPi
git clone git://git.drogon.net/wiringPi
cd wiringPi
./build


echo -e "\n→ ${bold}Installing avrdude-rpi${normal}\n";
cd /tmp
rm -fr avrdude-rpi
git clone https://github.com/dolink/avrdude-rpi
cd avrdude-rpi
cp autoreset avrdude /usr/local/bin

###################################################################
# Prepare
###################################################################

echo -e "\n→ ${bold}mkdir /usr/local/silo${normal}\n";
sudo mkdir -p /usr/local/silo

echo -e "\n→ ${bold}chowning /usr/local to ${username}${normal}\n";
sudo chown -R ${username} /usr/local

echo -e "\n→ ${bold}removing ~/tmp${normal}\n";
rm -fr ~/tmp
rm -fr /home/${username}/tmp

###################################################################
# Install global core node packages
###################################################################
echo -e "\n→ ${bold}[Node] Installing npd${normal}\n";
su ${username} -c "npm install npd -g"

echo -e "\n→ ${bold}[Node] Installing pm2${normal}\n";
su ${username} -c "npm install pm2 -g"

echo -e "\n→ ${bold}Installing agent${normal}\n";
su ${username} -c "npdg install @bb:dolink/agent"

echo -e "\n→ ${bold}Installing gateway wifi console${normal}\n";
su ${username} -c "npdg install @bb:dolink/gw-wifi"

echo -e "\n→ ${bold}Installing gateway${normal}\n";
su ${username} -c "npdg install @bb:dolink/gw"

echo -e "\n→ ${bold}Startup gateway${normal}\n";
sudo gw install

echo -e "\n→ ${bold}Starting gateway${normal}\n";
sudo gw start
