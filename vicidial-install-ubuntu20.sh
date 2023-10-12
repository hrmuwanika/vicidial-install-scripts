#!/bin/sh

echo "Vicidial installation Ubuntu 20.04 with WebPhone(WebRTC/SIP.js)"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update && sudo apt -y upgrade 
sudo apt autoremove -y

sudo apt -y install linux-headers-$(uname -r)
sudo apt install software-properties-common -y

# Add universe repository and install subversion
sudo add-apt-repository universe
sudo apt update 
sudo apt -y install subversion

#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
timedatectl set-timezone Africa/Kigali
timedatectl

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

# Install mariadb databases
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.6/ubuntu focal main'
sudo apt update 

sudo apt install mariadb-server mariadb-client -y 

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo rm /etc/mysql/mariadb.conf.d/50-server.cnf
cd /etc/mysql/mariadb.conf.d/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/50-server.cnf

sudo systemctl restart mariadb.service
sudo systemctl enable mariadb.service 

#sudo mysql_secure_installation

# Install PHP7.4
sudo add-apt-repository ppa:ondrej/php  -y
sudo apt update

sudo apt install php7.4 libapache2-mod-php7.4 php7.4-common php7.4-sqlite3 php7.4-json php7.4-curl php7.4-dev php7.4-readline php7.4-intl php7.4-mbstring \
php7.4-xmlrpc php7.4-mysql php7.4-ldap php7.4-gd php7.4-xml php7.4-cli php7.4-zip php7.4-soap php7.4-imap php7.4-bcmath php7.4-opcache -y

# install apache 
sudo apt install apache2 apache2-bin apache2-data apache2-utils libsvn-dev libapache2-mod-svn subversion subversion-tools -y 

# Other astguiclient dependencies
sudo apt install sox sipsak lame screen libploticus0-dev libsox-fmt-all mpg123 ploticus libnet-telnet-perl libasterisk-agi-perl \
libelf-dev shtool libdbd-mysql-perl libsrtp2-dev libedit-dev htop sngrep libcurl4 libelf-dev  -y

sudo a2enmod dav
sudo a2enmod dav_svn

sudo systemctl enable apache2.service
sudo systemctl restart apache2.service

# Install Asterisk 18 dependencies
sudo apt install build-essential autoconf subversion pkg-config libjansson-dev libxml2-dev uuid-dev libsqlite3-dev libtool automake libncurses5-dev \
git curl wget libnewt-dev libssl-dev subversion libmysqlclient-dev sqlite3 autogen -y

#Special package for ASTblind and ASTloop(ip_relay need this package)
sudo apt install libc6-i386 -y

#Install Jansson
cd /usr/src/
wget http://www.digip.org/jansson/releases/jansson-2.13.tar.gz
tar -zxf jansson-2.13.tar.gz
cd jansson-2.13
sudo ./configure
sudo make clean
sudo make
sudo make install 
sudo ldconfig

#Install CPAMN
cd /usr/bin/
apt install cpanminus -y
curl -LOk http://xrl.us/cpanm
chmod +x cpanm
cpanm readline --force
read -p 'Press Enter to continue Install perl modules: '

cpanm -f File::HomeDir
cpanm -f File::Which
cpanm CPAN::Meta::Requirements
cpanm -f CPAN
cpanm YAML
cpanm MD5
cpanm Digest::MD5
cpanm Digest::SHA1
cpanm Bundle::CPAN
cpanm DBI
cpanm -f DBD::mysql
cpanm Net::Telnet
cpanm Time::HiRes
cpanm Net::Server
cpanm Switch
cpanm Mail::Sendmail
cpanm Unicode::Map
cpanm Jcode
cpanm Spreadsheet::WriteExcel
cpanm OLE::Storage_Lite
cpanm Proc::ProcessTable
cpanm IO::Scalar
cpanm Spreadsheet::ParseExcel
cpanm Curses
cpanm Getopt::Long
cpanm Net::Domain
cpanm Term::ReadKey
cpanm Term::ANSIColor
cpanm Spreadsheet::XLSX
cpanm Spreadsheet::Read
cpanm LWP::UserAgent
cpanm HTML::Entities
cpanm HTML::Strip
cpanm HTML::FormatText
cpanm HTML::TreeBuilder
cpanm Time::Local
cpanm MIME::Decoder
cpanm Mail::POP3Client
cpanm Mail::IMAPClient
cpanm Mail::Message
cpanm IO::Socket::SSL
cpanm MIME::Base64
cpanm MIME::QuotedPrint
cpanm Crypt::Eksblowfish::Bcrypt
cpanm Crypt::RC4
cpanm Text::CSV
cpanm Text::CSV_XS

#If the DBD::MYSQL Fail Run below Command
sudo apt install libdbd-mysql-perl -y

read -p 'Press Enter to continue And Install Dahdi: '
#--------------------------------------------------
# Install dahdi
#--------------------------------------------------
echo "Install Dahdi"
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-3.2.0%2B3.2.0.tar.gz
tar xzf dahdi*
cd /usr/src/dahdi-linux-complete-3.2.0+3.2.0
sudo make
sudo make install
sudo make install-config

#apt install dahdi-* dahdi -y
#modprobe dahdi
#modprobe dahdi_dummy
#/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

read -p 'Press Enter to continue And Install LibPRI and Asterisk: '

#--------------------------------------------------
# Install Asterisk core 
#--------------------------------------------------
sudo mkdir /usr/src/asterisk
cd /usr/src/asterisk

# Download Asterisk 18 LTS tarball
wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18.19.0.tar.gz

# Extract the tarball file
tar -xvzf asterisk-18.19.0.tar.gz
cd asterisk-18*/

# Download the mp3 decoder library
sudo contrib/scripts/get_mp3_source.sh

# Ensure all dependencies are resolved
sudo contrib/scripts/install_prereq install

# Run the configure script to satisfy build dependencies
sudo ./configure 
sudo make clean

# Setup menu options by running the following command:
sudo make menuselect

# Use arrow keys to navigate, and Enter key to select. On Add-ons select chan_ooh323 and format_mp3 . 
# On Core Sound Packages, select the formats of Audio packets. Music On Hold, select 'Music onhold file package' 
# select Extra Sound Packages
# Enable app_macro under Applications menu
# Change other configurations as required

# Build Asterisk
sudo make

# Install Asterisk by running the command:
sudo make install

# Install configs and samples
sudo make samples
sudo make config
sudo ldconfig

# Create a separate user and group to run asterisk services, and assign correct permissions:
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo usermod -aG audio,dialout asterisk
sudo chown -R asterisk.asterisk /etc/asterisk
sudo chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk.asterisk /usr/lib/asterisk

#Set Asterisk default user to asterisk:
sudo nano /etc/default/asterisk
# AST_USER="asterisk"
# AST_GROUP="asterisk"

sudo nano /etc/asterisk/asterisk.conf
# runuser = asterisk ; The user to run as.
# rungroup = asterisk ; The group to run as.

# Problem: # *reference: https://www.clearhat.org/post/a-fix-for-apt-install-asterisk-on-ubuntu-18-04
# radcli: rc_read_config: rc_read_config: can't open /etc/radiusclient-ng/radiusclient.conf: No such file or directory
# Solution
sed -i 's";\[radius\]"\[radius\]"g' /etc/asterisk/cdr.conf
sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cdr.conf
sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cel.conf

# Restart asterisk service
sudo systemctl restart asterisk

# Enable asterisk service to start on system  boot
sudo systemctl enable asterisk

#--------------------------------------------------
# Install astguiclient
#--------------------------------------------------

# Install Perl Asterisk Extension
cd /usr/src
wget http://download.vicidial.com/required-apps/asterisk-perl-0.08.tar.gz
tar xzf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08/
perl Makefile.PL && sudo make all && sudo make install

echo "Installing astguiclient"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net/agc_2-X/trunk
cd /usr/src/astguiclient/trunk

#Add mysql users and Databases
echo "%%%%%%%%%%%%%%% Please Enter Mysql Password Or Just Press Enter if you Dont have Password %%%%%%%%%%%%%%%%%%%%%%%%%%"
mysql -u root -p << MYSQL_SCRIPT
SET GLOBAL connect_timeout=60;
CREATE DATABASE asterisk DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'cron'@'localhost' IDENTIFIED BY '1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@'%' IDENTIFIED BY '1234';
CREATE USER 'custom'@'localhost' IDENTIFIED BY 'custom1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO custom@'%' IDENTIFIED BY 'custom1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@localhost IDENTIFIED BY '1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO custom@localhost IDENTIFIED BY 'custom1234';
GRANT RELOAD ON *.* TO cron@'%';
GRANT RELOAD ON *.* TO cron@localhost;
GRANT RELOAD ON *.* TO custom@'%';
GRANT RELOAD ON *.* TO custom@localhost;
flush privileges;
use asterisk;
\. /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql
\. /usr/src/astguiclient/trunk/extras/first_server_install.sql
update servers set asterisk_version='18.19.0';
quit
MYSQL_SCRIPT

# Get astguiclient.conf file
echo "" > /etc/astguiclient.conf
wget -O /etc/astguiclient.conf https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/astguiclient.conf
echo "Replace IP address in Default"
echo "%%%%%%%%% Please Enter This Server IP ADD %%%%%%%%%%%%"
read serveripadd
sed -i 's/$serveripadd/'$serveripadd'/g' /etc/astguiclient.conf
echo "Install VICIDIAL"
echo "Copy sample configuration files to /etc/asterisk/ SET TO  Y*"
perl install.pl

#Secure Manager 
sed -i s/0.0.0.0/127.0.0.1/g /etc/asterisk/manager.conf

echo "Populate AREA CODES"
/usr/share/astguiclient/ADMIN_area_code_populate.pl

echo "Replace OLD IP. You need to Enter your Current IP here"
/usr/share/astguiclient/ADMIN_update_server_ip.pl --old-server_ip=10.10.10.15

#Install Crontab
wget -O /root/crontab-file https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/crontab
crontab /root/crontab-file
crontab -l

#Install rc.local
wget -O /etc/rc.local https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/rc.local
sudo chmod +x /etc/rc.local
sudo systemctl start rc-local

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5060/udp
sudo ufw allow 10000:20000/udp

read -p 'Press Enter to Reboot: '
echo "Now rebooting Ubuntu"

reboot





