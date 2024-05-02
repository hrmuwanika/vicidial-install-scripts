#!/bin/sh

echo -e "\n=== Vicidial installation Debian 12 (Bookworm) with WebPhone(WebRTC/SIP.js) ====="

export LC_ALL=C

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update && sudo apt -y upgrade 
sudo apt autoremove -y

sudo apt install -y lsb-release wget curl git flex libjansson* libedit* linux-headers-generic

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

#--------------------------------
# Remove mariadb strict mode 
#-------------------------------
cp /etc/my.cnf /etc/my.cnf.original
echo "" > /etc/my.cnf

cat <<MYSQLCONF>> /etc/my.cnf
[mysql.server]
user = mysql
#basedir = /var/lib

[client]
port = 3306
socket = /var/lib/mysql/mysql.sock

[mysqld]
datadir = /var/lib/mysql
#tmpdir = /home/mysql_tmp
socket = /var/lib/mysql/mysql.sock
user = mysql
old_passwords = 0
ft_min_word_len = 3
max_connections = 800
max_allowed_packet = 32M
skip-external-locking
sql_mode="NO_ENGINE_SUBSTITUTION"

log-error = /var/log/mysqld/mysqld.log

query-cache-type = 1
query-cache-size = 32M

long_query_time = 1
#slow_query_log = 1
#slow_query_log_file = /var/log/mysqld/slow-queries.log

tmp_table_size = 128M
table_cache = 1024

join_buffer_size = 1M
key_buffer = 512M
sort_buffer_size = 6M
read_buffer_size = 4M
read_rnd_buffer_size = 16M
myisam_sort_buffer_size = 64M

max_tmp_tables = 64

thread_cache_size = 8
thread_concurrency = 8

# If using replication, uncomment log-bin below
#log-bin = mysql-bin

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[isamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

[mysqld_safe]
#log-error = /var/log/mysqld/mysqld.log
#pid-file = /var/run/mysqld/mysqld.pid
MYSQLCONF

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

# install apache2
sudo apt install -y apache2 apache2-bin apache2-data apache2-utils libsvn-dev libapache2-mod-svn subversion subversion-tools  

# Other astguiclient dependencies
sudo apt install -y sox sipsak lame screen screenie libploticus0-dev libsox-fmt-all mpg123 ploticus libnet-telnet-perl libasterisk-agi-perl \
libelf-dev shtool libdbd-mariadb-perl libsrtp2-dev libedit-dev htop sngrep libcurl4 libelf-dev libmcrypt-dev mcrypt screenie iselect db5.3-util

sudo a2enmod dav
sudo a2enmod dav_svn

sudo systemctl enable apache2.service
sudo systemctl restart apache2.service

sudo rm /var/www/html/index.html

# Install Asterisk 20 dependencies
sudo apt install -y build-essential autoconf pkg-config libjansson-dev libxml2-dev uuid-dev libsqlite3-dev libtool automake libncurses5-dev \
libnewt-dev libssl-dev libmysqlclient-dev sqlite3 autogen uuid ntp 

# Special package for ASTblind and ASTloop(ip_relay need this package)
sudo apt install -y libc6-i386 

# Install Perl Modules
echo "Install Perl modules"
sudo apt install -y perl-CPAN perl-YAML perl-CPAN-DistnameInfo perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD perl-Env perl-Term-ReadLine-Gnu \
perl-SelfLoader perl-open.noarch 

cpan -i String::CRC Tk::TableMatrix Net::Address::IP::Local Term::ReadLine::Gnu 
Spreadsheet::Read Net::Address::IPv4::Local RPM::Specfile Spreadsheet::XLSX 
Spreadsheet::ReadSXC MD5 Digest::MD5 Digest::SHA1 Bundle::CPAN Pod::Usage 
Getopt::Long DBI DBD::mysql Net::Telnet Time::HiRes Net::Server Mail::Sendmail 
Unicode::Map Jcode Spreadsheet::WriteExcel OLE::Storage_Lite Proc::ProcessTable 
IO::Scalar Scalar::Util Spreadsheet::ParseExcel Archive::Zip Compress::Raw::Zlib 
Spreadsheet::XLSX Test::Tester Spreadsheet::ReadSXC Text::CSV Test::NoWarnings 
Text::CSV_PP File::Temp Text::CSV_XS Spreadsheet::Read LWP::UserAgent HTML::Entities 
HTML::Strip HTML::FormatText HTML::TreeBuilder Switch Time::Local MIME::POP3Client 
Mail::IMAPClient Mail::Message IO::Socket::SSL readline 

# Install CPAMN
cd /usr/bin/
apt install cpanminus -y
cpan> install Bundle::CPAN
cpan> reload cpan
cpan> install YAML
cpan> install MD5
cpan> install Digest::MD5
cpan> install Digest::SHA1
cpan> install readline
cpan> reload cpan
cpan> install DBI
cpan> force install DBD::mysql
cpan> install Net::Telnet
cpan> install Time::HiRes
cpan> install Net::Server
cpan> install Switch
cpan> install Mail::Sendmail
cpan> install Unicode::Map
cpan> install Jcode
cpan> install Spreadsheet::WriteExcel
cpan> install OLE::Storage_Lite
cpan> install Proc::ProcessTable
cpan> install IO::Scalar
cpan> install Spreadsheet::ParseExcel
cpan> install Curses
cpan> install Getopt::Long
cpan> install Net::Domain
cpan> install Term::ReadKey
cpan> install Term::ANSIColor
cpan> install Spreadsheet::XLSX
cpan> install Spreadsheet::Read
cpan> install LWP::UserAgent
cpan> install HTML::Entities
cpan> install HTML::Strip
cpan> install HTML::FormatText
cpan> install HTML::TreeBuilder
cpan> install Time::Local
cpan> install MIME::Decoder
cpan> install Mail::POP3Client
cpan> install Mail::IMAPClient
cpan> install Mail::Message
cpan> install IO::Socket::SSL
cpan> install MIME::Base64
cpan> install MIME::QuotedPrint
cpan> install Crypt::Eksblowfish::Bcrypt
cpan> quit 

# If the DBD::MYSQL Fail Run below Command
sudo apt install -y libdbd-mysql-perl

#Install Asterisk Perl
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
cd /usr/src/asterisk

# Download Asterisk 20 LTS tarball
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz

# Extract the tarball file
sudo tar -zxvf asterisk-20-current.tar.gz
cd asterisk-20*/

# Download the mp3 decoder library
sudo contrib/scripts/get_mp3_source.sh

# Ensure all dependencies are resolved
sudo apt update
sudo contrib/scripts/install_prereq install
make distclean

# Run the configure script to satisfy build dependencies
: ${JOBS:=$(( $(nproc) + $(nproc) / 2 ))}
sudo CFLAGS='-DENABLE_SRTP_AES_256 -DENABLE_SRTP_AES_GCM' ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled
make menuselect/menuselect menuselect-tree menuselect.makeopts
#enable app_meetme
menuselect/menuselect --enable app_meetme menuselect.makeopts
#enable res_http_websocket
menuselect/menuselect --enable res_http_websocket menuselect.makeopts
#enable res_srtp
menuselect/menuselect --enable res_srtp menuselect.makeopts
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

sudo sed -ie 's/;date.timezone =/date.timezone = Africa\/Kigali/g' /etc/php/8.2/cli/php.ini

tee -a /etc/php/8.2/apache2/php.ini <<EOF

error_reporting  =  E_ALL & ~E_NOTICE
memory_limit = 448M
short_open_tag = On
max_execution_time = 3330
max_input_time = 3360
post_max_size = 448M
upload_max_filesize = 442M
default_socket_timeout = 3360
date.timezone = Africa/Kigali
EOF

tee -a /etc/apache2/apache2.conf <<EOF
CustomLog /dev/null common
Alias /RECORDINGS/MP3 "/var/spool/asterisk/monitorDONE/MP3/"
<Directory "/var/spool/asterisk/monitorDONE/MP3/">
    Options Indexes MultiViews
    AllowOverride None
    Require all granted
</Directory>
EOF

sudo systemctl restart apache2

# Install Perl Asterisk Extension
cd /usr/src
wget https://github.com/hrmuwanika/vicidial-install-scripts/blob/main/asterisk-perl-0.08.tar.gz
tar -zxvf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08/
perl Makefile.PL && sudo make all && sudo make install

#Install astguiclient
echo "Installing astguiclient"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net:3690/agc_2-X/trunk
cd /usr/src/astguiclient/trunk

#Add mysql users and Databases
echo "%%%%%%%%%%%%%%% Please Enter Mysql Password Or Just Press Enter if you Dont have Password %%%%%%%%%%%%%%%%%%%%%%%%%%"
mysql -u root -p << MYSQLCREOF
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

SET GLOBAL connect_timeout=60;

use asterisk;
\. /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql
\. /usr/src/astguiclient/trunk/extras/first_server_install.sql
update servers set asterisk_version='20.7';
quit
MYSQLCREOF

# Get astguiclient.conf file
echo "" > /etc/astguiclient.conf
wget -O /etc/astguiclient.conf https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/astguiclient.conf
echo "Replace IP address in Default"
echo "%%%%%%%%% Please Enter This Server IP ADD %%%%%%%%%%%%"
read serveripadd
sed -i 's/$serveripadd/'$serveripadd'/g' /etc/astguiclient.conf
echo "Installing VICIDIAL"
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
sudo ufw reload

a2enmod ssl

read -p 'Press Enter to Reboot: '
echo "Restarting Debian"
reboot

# Admin Interface:
# http://yourserverip/vicidial/admin.php (username:6666, password:1234)

# Agent Interface:
# http://yourserverip/agc/vicidial.php (enter agent username and password which you have created through admin interface)
