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
sudo apt install -y mariadb-server mariadb-client libmariadb-dev libmysqlclient-dev 

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/51-server.cnf

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
sudo apt install -y apache2 apache2-bin apache2-data apache2-utils libsvn-dev libapache2-mod-php8.2 libapache2-mod-svn subversion subversion-tools  

# Other dependencies
sudo apt install -y sox lame screen libnet-telnet-perl libasterisk-agi-perl libelf-dev autogen libtool libnewt-dev libssl-dev unzip \
uuid-dev uuid libssl-dev git curl wget sipsak libploticus0-dev libsox-fmt-all mpg123 ploticus libelf-dev shtool patch libncurses5-dev \
libedit-dev htop sngrep libcurl4 libelf-dev build-essential libjansson-dev autoconf automake libxml2-dev libncurses5-dev libsqlite3-dev  \
pkg-config libxml2-dev libsqlite3-dev libtool automake sqlite3 ntp 

sudo a2enmod dav
sudo a2enmod dav_svn

sudo systemctl enable apache2.service
sudo systemctl restart apache2.service

sudo rm /var/www/html/index.html

# Special package for ASTblind and ASTloop(ip_relay need this package)
sudo apt install -y libc6-i386 

# Install CPAMN
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

# If the DBD::MYSQL Fail Run below Command
sudo apt install -y libdbd-mysql-perl libdbd-mariadb-perl

# Install Perl Asterisk Extension
cd /usr/src
wget http://download.vicidial.com/required-apps/asterisk-perl-0.08.tar.gz
tar xzf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08
perl Makefile.PL
make all
make install 

# Install Lame
cd /usr/src
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar -zxf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure
make
make install

# Install Jansson
cd /usr/src/
wget https://digip.org/jansson/releases/jansson-2.14.tar.gz
tar xvzf jansson*
cd jansson-2.14
./configure
make clean
make
make install 
ldconfig

echo "Press Enter to continue to install Dahdi "
# Download latest version of dahdi
apt-get install -y dahdi-* dahdi
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

# Download Asterisk 20 tarball
sudo wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz

# Extract the tarball file
sudo tar -xzvf asterisk-20-current.tar.gz
cd /usr/src/asterisk/asterisk-20.*/

# Download the mp3 decoder library
sudo ./contrib/scripts/get_mp3_source.sh

# Ensure all dependencies are resolved
sudo ./contrib/scripts/install_prereq install

# Run the configure script to satisfy build dependencies
sudo ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled

make menuselect

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
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/lib/asterisk
chown -R asterisk:asterisk /var/log/asterisk
chown -R asterisk:asterisk /var/spool/asterisk
chown -R asterisk:asterisk /usr/lib64/asterisk

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

sudo sytemctl enable asterisk
sudo sytemctl start asterisk

#--------------------------------------------------
# Install astguiclient
#--------------------------------------------------
rm /etc/localtime
ln -sf /usr/share/zoneinfo/Africa/Kigali /etc/localtime
systemctl restart ntpd

sudo sed -ie 's/;date.timezone =/date.timezone = Africa\/Kigali/g' /etc/php/8.2/apache2/php.ini
sudo sed -ie 's/;date.timezone =/date.timezone = Africa\/Kigali/g' /etc/php/8.2/cli/php.ini

# Install astguiclient
echo "Installing astguiclient"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net/agc_2-X/trunk
cd /usr/src/astguiclient/trunk

# Add mysql users and Databases
echo "%%%%%%%%%%%%%%% Please Enter Mysql Password Or Just Press Enter if you Dont have Password %%%%%%%%%%%%%%%%%%%%%%%%%%"
mariadb --user="root" --password="" -h localhost -e "CREATE DATABASE asterisk;"
mariadb --user="root" --password="" -h localhost -e "CREATE USER 'cron'@'localhost' IDENTIFIED BY '1234';";
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO cron@'%' IDENTIFIED BY '1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO cron@localhost IDENTIFIED BY '1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO cron@'%';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO cron@localhost;"
mariadb --user="root" --password="" -h localhost -e "CREATE USER 'custom'@'localhost' IDENTIFIED BY 'custom1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON on asterisk.* TO custom@'%' IDENTIFIED BY 'custom1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO custom@localhost IDENTIFIED BY 'custom1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO custom@'%';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO custom@localhost;"
mariadb --user="root" --password="" -h localhost -e "FLUSH PRIVILEGES;"
mariadb --user="root" --password="" -h localhost -e "SET GLOBAL connect_timeout=60;"
mariadb --user="root" --password="" asterisk < /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql
mariadb --user="root" --password="" asterisk < /usr/src/astguiclient/trunk/extras/first_server_install.sql
mariadb --user="root" --password="" asterisk -h localhost -e "update servers set asterisk_version='18.22.0';"
sudo systemctl restart mariadb 

# Get astguiclient.conf file
rm /etc/astguiclient.conf
wget -O /etc/astguiclient.conf https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/astguiclient.conf
echo "Replace IP address in Default"
echo "%%%%%%%%%Please Enter This Server IP ADD%%%%%%%%%%%%"
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

# Download rc.local to /etc
cd /etc
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/rc.local
sudo chmod +x /etc/rc.local

# Add rc-local as a service - thx to ras
cat > /etc/systemd/system/rc-local.service << EOF
[Unit]
Description=/etc/rc.local Compatibility

[Service]
Type=oneshot
ExecStart=/etc/rc.local
TimeoutSec=0
StandardInput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable rc-local.service
sudo systemctl start rc-local.service

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5060/udp
sudo ufw allow 5060/tcp
sudo ufw allow 10000:20000/udp

## Install Sounds
cd /var/lib/asterisk/sounds
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-wav-current.tar.gz

# Place the audio files in their proper places:
tar -zxf asterisk-core-sounds-en-gsm-current.tar.gz
tar -zxf asterisk-core-sounds-en-ulaw-current.tar.gz
tar -zxf asterisk-core-sounds-en-wav-current.tar.gz
tar -zxf asterisk-extra-sounds-en-gsm-current.tar.gz
tar -zxf asterisk-extra-sounds-en-ulaw-current.tar.gz
tar -zxf asterisk-extra-sounds-en-wav-current.tar.gz

# Remove tar files:
rm asterisk-core-sounds-en-gsm-current.tar.gz
rm asterisk-core-sounds-en-ulaw-current.tar.gz
rm asterisk-core-sounds-en-wav-current.tar.gz
rm asterisk-extra-sounds-en-gsm-current.tar.gz
rm asterisk-extra-sounds-en-ulaw-current.tar.gz
rm asterisk-extra-sounds-en-wav-current.tar.gz

read -p 'Press Enter to Reboot: '
echo "Now rebooting Ubuntu"
reboot

# Admin Interface:
# http://yourserverip/vicidial/admin.php (username:6666, password:1234)

# Agent Interface:
# http://yourserverip/agc/vicidial.php (enter agent username and password which you have created through admin interface)

