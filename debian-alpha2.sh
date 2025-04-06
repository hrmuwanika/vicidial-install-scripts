#!/bin/sh

echo "Vicidial installation Debian 12 with WebPhone(WebRTC/SIP.js)"

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
# set the correct timezone on Debian
timedatectl set-timezone Africa/Kigali

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

# Install mariadb databases
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=11.2
sudo apt update 
sudo apt install -y mariadb-server mariadb-client libmariadb-dev libmysqlclient-dev libmariadbclient-dev

sudo systemctl restart mariadb.service
sudo systemctl enable mariadb.service 

# sudo mysql_secure_installation

# Install PHP7.4
sudo apt install -y ca-certificates apt-transport-https software-properties-common 
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list 
sudo apt update

apt install -y uuid* libxml2*

sudo apt install -y php8.1 libapache2-mod-php8.1 php8.1-common php8.1-sqlite3 php8.1-curl php8.1-dev php8.1-readline php8.1-intl php8.1-mbstring \
php8.1-mysql php8.1-ldap php8.1-gd php8.1-xml php8.1-cli php8.1-zip php8.1-soap php8.1-imap php8.1-bcmath php8.1-opcache php8.1-ldap php8.1-json \
php8.1-mysqli php8.1-odbc php-pear php8.1-xmlrpc php8.1-mcrypt

##apt install -y sqlite-devel httpd mod_ssl nano chkconfig htop atop mytop iftop
apt install -y uuid* libxml2*

# install apache and subversion
sudo apt install -y apache2 apache2-bin apache2-data apache2-utils libsvn-dev libapache2-mod-svn subversion subversion-tools  
systemctl enable apache2
systemctl start apache2

# Other dependencies
sudo apt install -y sox lame screen libnet-telnet-perl libasterisk-agi-perl autogen libtool libnewt-dev libssl-dev unzip uuid-dev uuid libssl-dev \
git curl wget sipsak libploticus0-dev libsox-fmt-all mpg123 ploticus libelf-dev shtool patch libncurses5-dev libedit-dev htop sngrep libcurl4 make \
build-essential libjansson-dev autoconf automake libxml2-dev libsqlite3-dev pkg-config sqlite3 ntp 

sudo a2enmod dav
sudo a2enmod dav_svn

# Install Perl Modules
echo "Install Perl"
#apt install -y perl-CPAN perl-YAML perl-CPAN-DistnameInfo perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD perl-Env perl-Term-ReadLine-Gnu perl-SelfLoader perl-open.noarch 

cd /usr/bin/
curl -LOk http://xrl.us/cpanm
chmod +x cpanm
cpanm -f File::HomeDir
cpanm -f File::Which
cpanm CPAN::Meta::Requirements
cpanm -f CPAN
cpanm YAML
cpanm MD5
cpanm Digest::MD5
cpanm Digest::SHA1
cpanm readline --force

cpanm Bundle::CPAN
cpanm DBI
cpanm -f DBD::mysql
cpanm Net::Telnet
cpanm Time::HiRes
cpanm Net::Server
cpanm Switch
cpanm Mail::Sendmail --force
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

cpan install Crypt::Eksblowfish::Bcrypt
apt install libsrtp* -y

### up to this point

tee -a /etc/apache2/apache2.conf <<EOF

CustomLog /dev/null common

Alias /RECORDINGS/MP3 "/var/spool/asterisk/monitorDONE/MP3/"

<Directory "/var/spool/asterisk/monitorDONE/MP3/">
    Options Indexes MultiViews
    AllowOverride None
    Require all granted
</Directory>
EOF

tee -a /etc/php/7.4/apache2/php.ini <<EOF

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

systemctl restart apache2

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

mkdir /var/log/mysqld
touch /var/log/mysqld/slow-queries.log
chown -R mysql:mysql /var/log/mysqld
systemctl restart mariadb

systemctl enable apache2.service
systemctl enable mariadb.service
systemctl restart apache2.service
systemctl restart mariadb.service

# Special package for ASTblind and ASTloop(ip_relay need this package)
apt-get install libc6-i386 -y

# Install Jansson
cd /usr/src/
wget http://www.digip.org/jansson/releases/jansson-2.5.tar.gz
tar -zxf jansson-2.5.tar.gz
#tar xvzf jasson*
cd jansson-2.5
./configure
make clean
make
make install 
ldconfig

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
cpanm -f DBD::MariaDB
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

cpan install Crypt::Eksblowfish::Bcrypt

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
wget https://digip.org/jansson/releases/jansson-2.13.tar.gz
tar xvzf jansson*
cd jansson-2.13
./configure
make clean
make
make install 
ldconfig

cd /usr/src
wget https://github.com/cisco/libsrtp/archive/v2.1.0.tar.gz
tar xfv v2.1.0.tar.gz
cd libsrtp-2.1.0
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install
ldconfig


# Install Dahdi
echo "Install Dahdi"
sudo apt install -y dahdi-tools 
cd /usr/src && wget https://docs.phreaknet.org/script/phreaknet.sh && chmod +x phreaknet.sh && ./phreaknet.sh dahdi
modprobe dahdi
modprobe dahdi_dummy
/usr/sbin/dahdi_cfg -vvvvvvvvvv

sudo systemctl enable dahdi
sudo systemctl start dahdi
sudo systemctl status dahdi

#Install Asterisk and LibPRI
mkdir /usr/src/asterisk
cd /usr/src/asterisk
wget https://downloads.asterisk.org/pub/telephony/libpri/libpri-1.6.1.tar.gz
wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-18.18.1.tar.gz
tar -xvzf asterisk-*
tar -xvzf libpri-*

cd /usr/src
wget https://github.com/cisco/libsrtp/archive/v2.1.0.tar.gz
tar xfv v2.1.0.tar.gz
cd libsrtp-2.1.0
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install
ldconfig

cd /usr/src/asterisk/asterisk-18.18.1/
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

cd /usr/src/asterisk/asterisk-18.18.1/
patch < amd_stats-18.patch apps/app_amd.c
patch < iax_peer_status-18.patch channels/chan_iax2.c
patch < sip_peer_status-18.patch channels/chan_sip.c
patch < timeout_reset_dial_app-18.patch apps/app_dial.c
patch < timeout_reset_dial_core-18.patch main/dial.c

: ${JOBS:=$(( $(nproc) + $(nproc) / 2 ))}
./configure --libdir=/usr/lib64 --with-gsm=internal --enable-opus --enable-srtp --with-ssl --enable-asteriskssl --with-pjproject-bundled --with-jansson-bundled

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

# Install Asterisk by running the command:
make install

# Install configs and samples
make samples
make config
make basic-pbx

adduser asterisk --disabled-password --gecos "Asterisk User"

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

# Problem: # *reference: https://www.clearhat.org/post/a-fix-for-apt-install-asterisk-on-ubuntu-18-04
# radcli: rc_read_config: rc_read_config: can't open /etc/radiusclient-ng/radiusclient.conf: No such file or directory
# Solution
sed -i 's";\[radius\]"\[radius\]"g' /etc/asterisk/cdr.conf
sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cdr.conf
sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cel.conf

chkconfig asterisk off

rm /etc/localtime
ln -sf /usr/share/zoneinfo/Africa/Kigali /etc/localtime
systemctl restart ntpd

sudo sed -ie 's/;date.timezone =/date.timezone = Africa\/Kigali/g' /etc/php/7.4/cli/php.ini

#--------------------------------------------------
# Install astguiclient
#--------------------------------------------------
# Install astguiclient
echo "Installing astguiclient"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net/agc_2-X/trunk
cd /usr/src/astguiclient/trunk

# Add mysql users and Databases
echo "%%%%%%%%%%%%%%% Please Enter Mysql Password Or Just Press Enter if you Dont have Password %%%%%%%%%%%%%%%%%%%%%%%%%%"
mariadb --user="root" --password="" -h localhost -e "CREATE DATABASE asterisk;"
mariadb --user="root" --password="" -h localhost -e "CREATE USER 'cron'@'localhost' IDENTIFIED BY '1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO cron@'%' IDENTIFIED BY '1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO cron@localhost IDENTIFIED BY '1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO cron@'%';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO cron@localhost;"
mariadb --user="root" --password="" -h localhost -e "CREATE USER 'custom'@'localhost' IDENTIFIED BY 'custom1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO custom@'%' IDENTIFIED BY 'custom1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT ALL ON asterisk.* TO custom@localhost IDENTIFIED BY 'custom1234';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO custom@'%';"
mariadb --user="root" --password="" -h localhost -e "GRANT RELOAD ON *.* TO custom@localhost;"
mariadb --user="root" --password="" -h localhost -e "FLUSH PRIVILEGES;"
mariadb --user="root" --password="" -h localhost -e "SET GLOBAL connect_timeout=60;"
mariadb --user="root" --password="" asterisk < /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql
mariadb --user="root" --password="" asterisk < /usr/src/astguiclient/trunk/extras/first_server_install.sql
mariadb --user="root" --password="" asterisk -h localhost -e "update servers set asterisk_version='20.7';"
sudo systemctl restart mariadb 

sleep 5

# Get astguiclient.conf file
echo "" > /etc/astguiclient.conf
wget -O /etc/astguiclient.conf https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/astguiclient.conf
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

#Install Crontab
wget -O /root/crontab-file https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/crontab
crontab /root/crontab-file
crontab -l

#Install rc.local
wget -O /etc/rc.local https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/rc.local
chmod +x /etc/rc.local
systemctl start rc-local

cd /usr/src/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/confbridges.sh
chmod +x confbridges.sh
./confbridges.sh

cd /usr/src/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/confbridges.sh
chmod +x confbridges.sh
./confbridges.sh

apt install -y certbot python3-certbot-apache
systemctl enable certbot.timer
systemctl start certbot.timer

cd /usr/src/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/vicidial-enable-webrtc.sh
chmod +x vicidial-enable-webrtc.sh
./vicidial-enable-webrtc.sh

apt install firewalld -y
systemctl enable firewalld
systemctl start firewalld 

# Firewall configuration
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=446/tcp --permanent
firewall-cmd --zone=public --add-port=8089/tcp --permanent
firewall-cmd --zone=public --add-port=5060-5061/udp --permanent
firewall-cmd --zone=public --add-port=5060-5061/tcp --permanent
firewall-cmd --zone=public --add-port=10000-20000/udp --permanent
firewall-cmd --reload

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

cd /var/lib/asterisk/quiet-mp3
sox ../mohmp3/macroform-cold_day.wav macroform-cold_day.wav vol 0.25
sox ../mohmp3/macroform-cold_day.gsm macroform-cold_day.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/macroform-cold_day.ulaw -t ul macroform-cold_day.ulaw vol 0.25
sox ../mohmp3/macroform-robot_dity.wav macroform-robot_dity.wav vol 0.25
sox ../mohmp3/macroform-robot_dity.gsm macroform-robot_dity.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/macroform-robot_dity.ulaw -t ul macroform-robot_dity.ulaw vol 0.25
sox ../mohmp3/macroform-the_simplicity.wav macroform-the_simplicity.wav vol 0.25
sox ../mohmp3/macroform-the_simplicity.gsm macroform-the_simplicity.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/macroform-the_simplicity.ulaw -t ul macroform-the_simplicity.ulaw vol 0.25
sox ../mohmp3/reno_project-system.wav reno_project-system.wav vol 0.25
sox ../mohmp3/reno_project-system.gsm reno_project-system.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/reno_project-system.ulaw -t ul reno_project-system.ulaw vol 0.25
sox ../mohmp3/manolo_camp-morning_coffee.wav manolo_camp-morning_coffee.wav vol 0.25
sox ../mohmp3/manolo_camp-morning_coffee.gsm manolo_camp-morning_coffee.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/manolo_camp-morning_coffee.ulaw -t ul manolo_camp-morning_coffee.ulaw vol 0.25

tee -a ~/.bashrc <<EOF

# Commands
/usr/share/astguiclient/ADMIN_keepalive_ALL.pl --cu3way
/usr/share/astguiclient/AST_VDhopper.pl -q
EOF

chmod -R 777 /var/spool/asterisk/monitorDONE
chown -R apache:apache /var/spool/asterisk/monitorDONE

cat > /var/www/html/index.html <<WELCOME
<META HTTP-EQUIV=REFRESH CONTENT="1; URL=/vicidial/welcome.php">
Please Hold while I redirect you!
WELCOME

read -p 'Press Enter to Reboot: '
echo "Restarting Debian"
reboot
