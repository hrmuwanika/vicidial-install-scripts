#!/bin/sh

echo "=== Vicidial installation Debian 12 (Bookworm) with WebPhone(WebRTC/SIP.js) ====="

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update && sudo apt -y upgrade 
sudo apt autoremove -y

# Install linux headers
sudo apt -y install linux-headers-$(uname -r)

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
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=11.2
sudo apt update 

sudo apt install -y mariadb-server mariadb-client libmariadb-dev 

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo rm /etc/mysql/mariadb.conf.d/50-server.cnf
cd /etc/mysql/mariadb.conf.d/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/50-server.cnf

sudo systemctl restart mariadb.service
sudo systemctl enable mariadb.service 

# sudo mysql_secure_installation

# Install PHP8.2
sudo apt install -y ca-certificates apt-transport-https software-properties-common 
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list 
sudo apt update

sudo apt install -y php8.2 libapache2-mod-php8.2 php8.2-common php8.2-sqlite3 php8.2-curl php8.2-dev php8.2-readline php8.2-intl php8.2-mbstring \
php8.2-xmlrpc php8.2-mysql php8.2-ldap php8.2-gd php8.2-xml php8.2-cli php8.2-zip php8.2-soap php8.2-imap php8.2-bcmath php8.2-opcache 

# install apache and subversion
sudo apt install -y apache2 apache2-bin apache2-data apache2-utils libsvn-dev libapache2-mod-svn subversion subversion-tools  

# Other astguiclient dependencies
sudo apt install -y sox sipsak lame screen libploticus0-dev libsox-fmt-all mpg123 ploticus libnet-telnet-perl libasterisk-agi-perl \
libelf-dev shtool libdbd-mariadb-perl libsrtp2-dev libedit-dev htop sngrep libcurl4 libelf-dev 

sudo a2enmod dav
sudo a2enmod dav_svn

sudo systemctl enable apache2.service
sudo systemctl restart apache2.service

sudo rm /var/www/html/index.html

# Install Asterisk 18 dependencies
sudo apt install -y build-essential autoconf pkg-config libjansson-dev libxml2-dev uuid-dev libsqlite3-dev libtool automake libncurses5-dev \
git curl wget libnewt-dev libssl-dev  libmysqlclient-dev sqlite3 autogen uuid ntp 

# Special package for ASTblind and ASTloop(ip_relay need this package)
sudo apt install -y libc6-i386 

# Install CPAMN
cd /usr/bin/
apt install -y cpanminus 
curl -LOk http://xrl.us/cpanm
chmod +x cpanm
cpanm readline --force
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

# If the DBD::MYSQL Fail Run below Command
sudo apt install -y libdbd-mysql-perl

# Install Perl Asterisk Extension
cd /usr/src
wget http://download.vicidial.com/required-apps/asterisk-perl-0.08.tar.gz
tar xzf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08
perl Makefile.PL
make all
make install 

#Install Lame
cd /usr/src
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar -zxf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure
make
make install

# Install Jansson
cd /usr/src/
wget https://digip.org/jansson/releases/jansson-2.13.tar.gz
tar xvzf jansson*
cd jansson-2.13
./configure
make clean
make
make install 
ldconfig

echo "Press Enter to continue to install Asterisk: "
# Download latest version of dahdi
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
tar -zxvf dahdi-linux-complete-current.tar.gz
cd dahdi-linux-complete-3.*
make clean
make 
make install
make config
cd tools/
./configure
cd ..
make install-config

cp /etc/dahdi/system.conf.sample /etc/dahdi/system.conf
modprobe dahdi
modprobe dahdi_dummy
/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

# Install and compile libpri
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1-current.tar.gz
tar -zxvf libpri-1-current.tar.gz
cd libpri-1.*
make
make install

#--------------------------------------------------
# Install Asterisk core 
#--------------------------------------------------
mkdir /usr/src/asterisk
cd /usr/src/asterisk

# Download Asterisk 18 tarball
sudo wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz

# Extract the tarball file
sudo tar -xzvf asterisk-18-current.tar.gz
cd /usr/src/asterisk/asterisk-18.*/

wget http://download.vicidial.com/asterisk-patches/Asterisk-18/amd_stats-18.patch
wget http://download.vicidial.com/asterisk-patches/Asterisk-18/iax_peer_status-18.patch
wget http://download.vicidial.com/asterisk-patches/Asterisk-18/sip_peer_status-18.patch
wget http://download.vicidial.com/asterisk-patches/Asterisk-18/timeout_reset_dial_app-18.patch
wget http://download.vicidial.com/asterisk-patches/Asterisk-18/timeout_reset_dial_core-18.patch
cd apps/
wget http://download.vicidial.com/asterisk-patches/Asterisk-18/enter.h
wget http://download.vicidial.com/asterisk-patches/Asterisk-18/leave.h
yes | cp -rf enter.h.1 enter.h
yes | cp -rf leave.h.1 leave.h

cd /usr/src/asterisk/asterisk-18.*/
patch < amd_stats-18.patch apps/app_amd.c
patch < iax_peer_status-18.patch channels/chan_iax2.c
patch < sip_peer_status-18.patch channels/chan_sip.c
patch < timeout_reset_dial_app-18.patch apps/app_dial.c
patch < timeout_reset_dial_core-18.patch main/dial.c

# Download the mp3 decoder library
sudo contrib/scripts/get_mp3_source.sh

# Ensure all dependencies are resolved
sudo apt update
sudo contrib/scripts/install_prereq install
make distclean

# Run the configure script to satisfy build dependencies
${JOBS:=$(( $(nproc) + $(nproc) / 2 ))}
sudo CFLAGS='-DENABLE_SRTP_AES_256 -DENABLE_SRTP_AES_GCM' ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled
# Setup menu options by running the following command:
make menuselect/menuselect menuselect-tree menuselect.makeopts
#enable app_meetme
menuselect/menuselect --enable app_meetme menuselect.makeopts
#enable res_http_websocket
menuselect/menuselect --enable res_http_websocket menuselect.makeopts
#enable res_srtp
menuselect/menuselect --enable res_srtp menuselect.makeopts
make samples
sed -i 's|noload = chan_sip.so|;noload = chan_sip.so|g' /etc/asterisk/modules.conf
make -j ${JOBS} all

# Use arrow keys to navigate, and Enter key to select. On Add-ons select chan_ooh323 and format_mp3 . 
# On Core Sound Packages, select the formats of Audio packets. Music On Hold, select 'Music onhold file package' 
# select Extra Sound Packages
# Enable app_macro under Applications menu
# Change other configurations as required
adduser asterisk --disabled-password --gecos "Asterisk User"

# Build Asterisk
sudo make

# Install Asterisk by running the command:
sudo make install

# Install configs and samples
sudo make samples
sudo make config

# Create a separate user and group to run asterisk services, and assign correct permissions:
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/lib/asterisk
chown -R asterisk.asterisk /var/log/asterisk
chown -R asterisk.asterisk /var/spool/asterisk
chown -R asterisk.asterisk /usr/lib64/asterisk

#Set Asterisk default user to asterisk:
sed -i 's|#AST_USER|AST_USER|' /etc/default/asterisk
sed -i 's|#AST_GROUP|AST_GROUP|' /etc/default/asterisk

sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf
sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf

echo "/usr/lib64" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf
sudo ldconfig

# Problem: # *reference: https://www.clearhat.org/post/a-fix-for-apt-install-asterisk-on-ubuntu-18-04
# radcli: rc_read_config: rc_read_config: can't open /etc/radiusclient-ng/radiusclient.conf: No such file or directory
# Solution
sed -i 's";\[radius\]"\[radius\]"g' /etc/asterisk/cdr.conf
sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cdr.conf
sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cel.conf

# Enable asterisk service to start on system  boot
sudo systemctl daemon-reload
sudo systemctl enable asterisk
sudo systemctl restart asterisk

#--------------------------------------------------
# Install astguiclient
#--------------------------------------------------
rm /etc/localtime
ln -sf /usr/share/zoneinfo/Africa/Kigali /etc/localtime
systemctl restart ntpd

sudo sed -ie 's/;date.timezone =/date.timezone = Africa\/Kigali/g' /etc/php/8.2/apache2/php.ini
sudo sed -ie 's/;date.timezone =/date.timezone = Africa\/Kigali/g' /etc/php/8.2/cli/php.ini

echo "========== Installing astguiclient ============"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net/agc_2-X/trunk

cd /usr/src/astguiclient/trunk/extras/ConfBridge/
cp * /usr/share/astguiclient/
cd /usr/share/astguiclient/
mv manager_send.php.diff vdc_db_query.php.diff vicidial.php.diff /var/www/html/agc/
patch -p0 < ADMIN_keepalive_ALL.pl.diff
patch -p0 < ADMIN_update_server_ip.pl.diff
patch -p0 < AST_DB_optimize.pl.diff
chmod +x AST_conf_update_screen.pl
patch -p0 < AST_reset_mysql_vars.pl.diff
cd /var/www/html/agc/
patch -p0 < manager_send.php.diff
patch -p0 < vdc_db_query.php.diff
patch -p0 < vicidial.php.diff

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
update servers set asterisk_version='18.22.0';
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

# Install Crontab
wget -O /root/crontab-file https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/crontab
crontab /root/crontab-file
crontab -l

# Install rc.local
wget -O /etc/rc.local https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/rc.local
sudo chmod +x /etc/rc.local
sudo systemctl start rc-local

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5060/udp
sudo ufw allow 5060/tcp
sudo ufw allow 10000:20000/udp

echo "Now rebooting Ubuntu"

reboot

# Admin Interface:
# http://yourserverip/vicidial/admin.php (username:6666, password:1234)

# Agent Interface:
# http://yourserverip/agc/vicidial.php (enter agent username and password which you have created through admin interface)

