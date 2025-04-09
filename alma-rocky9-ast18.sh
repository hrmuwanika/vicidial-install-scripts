#!/bin/sh

echo "==================================================================================="
echo "Vicidial installation and Asterisk 18 on AlmaLinux/RockyLinux"
echo "==================================================================================="

# Function to prompt user for input
prompt() {
    local varname=$1
    local prompt_text=$2
    local default_value=$3
    read -p "$prompt_text [$default_value]: " input
    export $varname="${input:-$default_value}"
}

echo "Getting Machine info - No hostname? Enter the IP Address"
echo "**************************************************************************"
prompt hostname "Enter the hostname:" "$hostname"
echo "Press Enter to continue"
read
hostnamectl set-hostname $hostname
# Retrieve the Hostname
hostname=$(hostname | awk '{print $1}')
echo "Hostname\t: $hostname"
# Retrieve the IP address
ip_address=$(hostname -I | awk '{print $1}')
echo "IP Address\t: $ip_address"
echo "**************************************************************************"
echo "Enter to continue..."
read	

# Set the timezone
timedatectl set-timezone Africa/Kigali

# Disable SELINUX
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config  
setenforce 0

yum -y install openssh-server

# Enable root access to ssh
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

export LC_ALL=C

tee -a /etc/systemd/system.conf <<EOF
DefaultLimitNOFILE=65536
EOF

# Update Server
yum check-update
yum -y update
yum -y install epel-release
yum -y update

yum -y install nano tar openssh-server
yum -y groupinstall 'Development Tools'
yum -y install kernel* --exclude=kernel-debug* 

# Updating YUM Repos
yum -y install yum-utils
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum -y install http://rpms.remirepo.net/enterprise/remi-release-9.rpm
dnf -y module enable php:remi-8.2
# dnf -y module enable mariadb:10.5 

dnf -y install dnf-plugins-core

sudo yum -y install php screen php-mcrypt subversion php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-opcache php-fpm php-mysqlnd
sudo yum -y install wget unzip make patch gcc gcc-c++ subversion php php-devel php-gd gd-devel readline-devel php-mbstring php-devel
sudo yum -y install php-imap php-mysqli php-odbc php-pear php-xml php-xmlrpc curl curl-devel perl-libwww-perl ImageMagick php-bcmath php-json
sudo yum -y install initscripts python3-pip libxcrypt-compat

sudo yum -y install httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service

sudo cat <<EOF > /etc/yum.repos.d/mariadb.repo

[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.11/rhel9-amd64
module_hotfixes=1
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1 
EOF

sudo dnf update -y
sudo dnf module reset mariadb -y

sudo dnf -y install  mariadb-server mariadb
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service

yum -y install sox lame-devel php-opcache libss7 libss7* 

sudo yum -y install newt-devel libxml2* libxml2-devel kernel-devel sqlite-devel libuuid-devel perl-File-Which dmidecode gcc-c++ 
sudo yum -y install libopen* unzip libpcap libnet ncurses ncurses-devel mutt net-tools logrotate htop gd-devel make patch 
sudo yum -y install openssl openssl-devel unixODBC libtool-ltdl speex libtool automake autoconf uuid* gtk2-devel binutils-devel libedit libedit-devel

### Install cockpit
sudo yum -y install cockpit cockpit-storaged cockpit-navigator
sed -i s/root/"#root"/g /etc/cockpit/disallowed-users
sudo systemctl enable cockpit.socket

# Install certbot
sudo dnf -y install certbot python3-certbot-apache mod_ssl

sudo yum -y copr enable irontec/sngrep 
sudo dnf -y install sngrep 

dnf --enablerepo=crb install libsrtp-devel -y
dnf config-manager --set-enabled crb

sudo yum -y install libsrtp-devel 
sudo yum -y install elfutils-libelf-devel

tee -a /etc/httpd/conf/httpd.conf <<EOF
CustomLog /dev/null common

Alias /RECORDINGS/MP3 "/var/spool/asterisk/monitorDONE/MP3/"

<Directory "/var/spool/asterisk/monitorDONE/MP3/">
    Options Indexes MultiViews
    AllowOverride None
    Require all granted
</Directory>
EOF

tee -a /etc/php.ini <<EOF
error_reporting  =  E_ALL & ~E_NOTICE
memory_limit = 448M
short_open_tag = On
max_execution_time = 3330
max_input_time = 3360
post_max_size = 448M
upload_max_filesize = 442M
default_socket_timeout = 3360
date.timezone = Africa/Kigali
max_input_vars = 50000
upload_tmp_dir =/tmp
EOF

sudo systemctl restart httpd

yum -y install chkconfig atop mytop htop
yum -y install libedit-devel uuid* libxml2* speex-devel speex* dovecot s-nail roundcubemail inxi
yum -y install sendmail postfix
systemctl enable postfix
systemctl start postfix

dnf -y install dnf-plugins-core
dnf config-manager --set-enabled powertools

cp /etc/my.cnf /etc/my.cnf.original
echo "" > /etc/my.cnf

cat > /etc/my.cnf <<MYSQLCONF
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

join_buffer_size = 33M
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
default_time_zone = 'Africa/Kigali'
MYSQLCONF

mkdir /var/log/mysqld
touch /var/log/mysqld/slow-queries.log
chown -R mysql:mysql /var/log/mysqld

systemctl restart httpd.service
systemctl restart mariadb.service

# Install Perl Modules
echo "Install Perl"
yum -y install perl-CPAN perl-YAML perl-CPAN-DistnameInfo perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD perl-Env perl-Term-ReadLine-Gnu perl-SelfLoader perl-open.noarch 

cpan -i Tk String::CRC Tk::TableMatrix Net::Address::IP::Local Term::ReadLine::Gnu XML::Twig Digest::Perl::MD5 Spreadsheet::Read Net::Address::IPv4::Local RPM::Specfile \
Spreadsheet::XLSX Spreadsheet::ReadSXC MD5 Digest::MD5 Digest::SHA1 Bundle::CPAN Pod::Usage Getopt::Long DBI DBD::mysql Net::Telnet Time::HiRes Net::Server Mail::Sendmail \
Unicode::Map Jcode Spreadsheet::WriteExcel OLE::Storage_Lite Proc::ProcessTable IO::Scalar Scalar::Util Spreadsheet::ParseExcel Archive::Zip Compress::Raw::Zlib Spreadsheet::XLSX \
Test::Tester Spreadsheet::ReadSXC Text::CSV Test::NoWarnings Text::CSV_PP File::Temp Text::CSV_XS Spreadsheet::Read LWP::UserAgent HTML::Entities HTML::Strip HTML::FormatText \
HTML::TreeBuilder Switch Time::Local Mail::POP3Client Mail::IMAPClient Mail::Message IO::Socket::SSL readline

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
cpanm DBD::mysql --force
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

# CPM install
cd /usr/src
curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g App::cpm
/usr/local/bin/cpm install -g

# Install Asterisk Perl
cd /usr/src
wget http://download.vicidial.com/required-apps/asterisk-perl-0.08.tar.gz
tar xzf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08
perl Makefile.PL
make all
make install 

# Install sipsak
cd /usr/src
wget http://download.vicidial.com/required-apps/sipsak-0.9.6-1.tar.gz
tar -zxf sipsak-0.9.6-1.tar.gz
cd sipsak-0.9.6
./configure
make
make install
/usr/local/bin/sipsak --version

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

cd /usr/src/
git clone https://github.com/akheron/jansson.git
cd jansson
autoreconf  -i
./configure --prefix=/usr/
make && make install

# Installation of eaccelerator
cd /usr/src/
wget https://github.com/eaccelerator/eaccelerator/zipball/master -O eaccelerator.zip
unzip eaccelerator.zip
cd eaccelerator-*
export PHP_PREFIX=”/usr”
$PHP_PREFIX/bin/phpize
./configure –enable-eaccelerator=shared –with-php-config=$PHP_PREFIX/bin/php-config
make

# Download and Install PJSIP
cd /usr/src/ 
git clone https://github.com/pjsip/pjproject.git
cd pjproject
./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr
make dep
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
sudo dnf -y install dahdi-tools 
cd /usr/src && wget https://docs.phreaknet.org/script/phreaknet.sh && chmod +x phreaknet.sh && ./phreaknet.sh dahdi
modprobe dahdi
modprobe dahdi_dummy
/usr/sbin/dahdi_cfg -vvvvvvvvvv

sudo systemctl enable dahdi
sudo systemctl start dahdi
sudo systemctl status dahdi

# Install Asterisk and LibPRI
cd /usr/src/
wget https://downloads.asterisk.org/pub/telephony/libpri/libpri-1.6.1.tar.gz
wget http://download.vicidial.com/required-apps/asterisk-18.21.0-vici.tar.gz
tar -xvzf asterisk-18.21.0-vici.tar.gz
tar -xvzf libpri-1.6.1.tar.gz

cd /usr/src/asterisk-18.21.0-vici
./contrib/scripts/install_prereq install
./contrib/scripts/get_mp3_source.sh

yum -y install libuuid-devel libxml2-devel 

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
make install

#Install configs and samples
sudo make samples

adduser asterisk -s /bin/bash -c "Asterisk User"

# Create a separate user and group to run asterisk services, and assign correct permissions:
groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
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

#--------------------------------------------------
# Install astguiclient
#--------------------------------------------------
echo "Installing astguiclient"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net/agc_2-X/trunk
cd /usr/src/astguiclient/trunk

#Add mysql users and Databases
echo "%%%%%%%%%%%%%%%Please Enter Mysql Password Or Just Press Enter if you Dont have Password%%%%%%%%%%%%%%%%%%%%%%%%%%"
mysql -u root -p << MYSQLCREOF
CREATE DATABASE asterisk DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'cron'@'localhost' IDENTIFIED BY '1234';
GRANT SELECT,CREATE,ALTER,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@'%' IDENTIFIED BY '1234';
GRANT SELECT,CREATE,ALTER,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@localhost IDENTIFIED BY '1234';
GRANT RELOAD ON *.* TO cron@'%';
GRANT RELOAD ON *.* TO cron@localhost;
CREATE USER 'custom'@'localhost' IDENTIFIED BY 'custom1234';
GRANT SELECT,CREATE,ALTER,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO custom@'%' IDENTIFIED BY 'custom1234';
GRANT SELECT,CREATE,ALTER,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO custom@localhost IDENTIFIED BY 'custom1234';
GRANT RELOAD ON *.* TO custom@'%';
GRANT RELOAD ON *.* TO custom@localhost;
flush privileges;

SET GLOBAL connect_timeout=60;

use asterisk;
\. /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql
\. /usr/src/astguiclient/trunk/extras/first_server_install.sql
update servers set asterisk_version='18.21.0-vici';
quit
MYSQLCREOF

# update the timezone
cp /usr/share/zoneinfo/Africa/Kigali /etc/localtime

# Get astguiclient.conf file
cat > /etc/astguiclient.conf <<ASTGUI
# astguiclient.conf - configuration elements for the astguiclient package
# this is the astguiclient configuration file
# all comments will be lost if you run install.pl again

# Paths used by astGUIclient
PATHhome => /usr/share/astguiclient
PATHlogs => /var/log/astguiclient
PATHagi => /var/lib/asterisk/agi-bin
PATHweb => /var/www/html
PATHsounds => /var/lib/asterisk/sounds
PATHmonitor => /var/spool/asterisk/monitor
PATHDONEmonitor => /var/spool/asterisk/monitorDONE

# The IP address of this machine
VARserver_ip => SERVERIP

# Database connection information
VARDB_server => localhost
VARDB_database => asterisk
VARDB_user => cron
VARDB_pass => 1234
VARDB_custom_user => custom
VARDB_custom_pass => custom1234
VARDB_port => 3306

# Alpha-Numeric list of the astGUIclient processes to be kept running
# (value should be listing of characters with no spaces: 123456)
#  X - NO KEEPALIVE PROCESSES (use only if you want none to be keepalive)
#  1 - AST_update
#  2 - AST_send_listen
#  3 - AST_VDauto_dial
#  4 - AST_VDremote_agents
#  5 - AST_VDadapt (If multi-server system, this must only be on one server)
#  6 - FastAGI_log
#  7 - AST_VDauto_dial_FILL (only for multi-server, this must only be on one server)
#  8 - ip_relay (used for blind agent monitoring)
#  9 - Timeclock auto logout
#  E - Email processor, (If multi-server system, this must only be on one server)
#  S - SIP Logger (Patched Asterisk 13 required)
VARactive_keepalives => 12345689EC

# Asterisk version VICIDIAL is installed for
VARasterisk_version => 18.X

# FTP recording archive connection information
VARFTP_host => 10.0.0.4
VARFTP_user => cron
VARFTP_pass => test
VARFTP_port => 21
VARFTP_dir => RECORDINGS
VARHTTP_path => http://10.0.0.4

# REPORT server connection information
VARREPORT_host => 10.0.0.4
VARREPORT_user => cron
VARREPORT_pass => test
VARREPORT_port => 21
VARREPORT_dir => REPORTS

# Settings for FastAGI logging server
VARfastagi_log_min_servers => 3
VARfastagi_log_max_servers => 16
VARfastagi_log_min_spare_servers => 2
VARfastagi_log_max_spare_servers => 8
VARfastagi_log_max_requests => 1000
VARfastagi_log_checkfordead => 30
VARfastagi_log_checkforwait => 60

# Expected DB Schema version for this install
ExpectedDBSchema => 1645
ASTGUI

echo "Replace IP address in Default"
#echo "%%%%%%%%%Please Enter This Server IP ADD%%%%%%%%%%%%"
#read serveripadd
sed -i s/SERVERIP/"$ip_address"/g /etc/astguiclient.conf

echo "Install VICIDIAL"
perl install.pl --no-prompt --copy_sample_conf_files=Y

# Secure Manager 
sed -i s/0.0.0.0/127.0.0.1/g /etc/asterisk/manager.conf

#Add confbridge conferences to asterisk DB
mysql -u root -e "use asterisk; INSERT INTO `vicidial_confbridges` VALUES 
(9600000,'$ip_address','','0',NULL),
(9600001,'$ip_address','','0',NULL),
(9600002,'$ip_address','','0',NULL),
(9600003,'$ip_address','','0',NULL),
(9600004,'$ip_address','','0',NULL),
(9600005,'$ip_address','','0',NULL),
(9600006,'$ip_address','','0',NULL),
(9600007,'$ip_address','','0',NULL),
(9600008,'$ip_address','','0',NULL),
(9600009,'$ip_address','','0',NULL),
(9600010,'$ip_address','','0',NULL),
(9600011,'$ip_address','','0',NULL),
(9600012,'$ip_address','','0',NULL),
(9600013,'$ip_address','','0',NULL),
(9600014,'$ip_address','','0',NULL),
(9600015,'$ip_address','','0',NULL),
(9600016,'$ip_address','','0',NULL),
(9600017,'$ip_address','','0',NULL),
(9600018,'$ip_address','','0',NULL),
(9600019,'$ip_address','','0',NULL),
(9600020,'$ip_address','','0',NULL),
(9600021,'$ip_address','','0',NULL),
(9600022,'$ip_address','','0',NULL),
(9600023,'$ip_address','','0',NULL),
(9600024,'$ip_address','','0',NULL),
(9600025,'$ip_address','','0',NULL),
(9600026,'$ip_address','','0',NULL),
(9600027,'$ip_address','','0',NULL),
(9600028,'$ip_address','','0',NULL),
(9600029,'$ip_address','','0',NULL),
(9600030,'$ip_address','','0',NULL),
(9600031,'$ip_address','','0',NULL),
(9600032,'$ip_address','','0',NULL),
(9600033,'$ip_address','','0',NULL),
(9600034,'$ip_address','','0',NULL),
(9600035,'$ip_address','','0',NULL),
(9600036,'$ip_address','','0',NULL),
(9600037,'$ip_address','','0',NULL),
(9600038,'$ip_address','','0',NULL),
(9600039,'$ip_address','','0',NULL),
(9600040,'$ip_address','','0',NULL),
(9600041,'$ip_address','','0',NULL),
(9600042,'$ip_address','','0',NULL),
(9600043,'$ip_address','','0',NULL),
(9600044,'$ip_address','','0',NULL),
(9600045,'$ip_address','','0',NULL),
(9600046,'$ip_address','','0',NULL),
(9600047,'$ip_address','','0',NULL),
(9600048,'$ip_address','','0',NULL),
(9600049,'$ip_address','','0',NULL),
(9600050,'$ip_address','','0',NULL),
(9600051,'$ip_address','','0',NULL),
(9600052,'$ip_address','','0',NULL),
(9600053,'$ip_address','','0',NULL),
(9600054,'$ip_address','','0',NULL),
(9600055,'$ip_address','','0',NULL),
(9600056,'$ip_address','','0',NULL),
(9600057,'$ip_address','','0',NULL),
(9600058,'$ip_address','','0',NULL),
(9600059,'$ip_address','','0',NULL),
(9600060,'$ip_address','','0',NULL),
(9600061,'$ip_address','','0',NULL),
(9600062,'$ip_address','','0',NULL),
(9600063,'$ip_address','','0',NULL),
(9600064,'$ip_address','','0',NULL),
(9600065,'$ip_address','','0',NULL),
(9600066,'$ip_address','','0',NULL),
(9600067,'$ip_address','','0',NULL),
(9600068,'$ip_address','','0',NULL),
(9600069,'$ip_address','','0',NULL),
(9600070,'$ip_address','','0',NULL),
(9600071,'$ip_address','','0',NULL),
(9600072,'$ip_address','','0',NULL),
(9600073,'$ip_address','','0',NULL),
(9600074,'$ip_address','','0',NULL),
(9600075,'$ip_address','','0',NULL),
(9600076,'$ip_address','','0',NULL),
(9600077,'$ip_address','','0',NULL),
(9600078,'$ip_address','','0',NULL),
(9600079,'$ip_address','','0',NULL),
(9600080,'$ip_address','','0',NULL),
(9600081,'$ip_address','','0',NULL),
(9600082,'$ip_address','','0',NULL),
(9600083,'$ip_address','','0',NULL),
(9600084,'$ip_address','','0',NULL),
(9600085,'$ip_address','','0',NULL),
(9600086,'$ip_address','','0',NULL),
(9600087,'$ip_address','','0',NULL),
(9600088,'$ip_address','','0',NULL),
(9600089,'$ip_address','','0',NULL),
(9600090,'$ip_address','','0',NULL),
(9600091,'$ip_address','','0',NULL),
(9600092,'$ip_address','','0',NULL),
(9600093,'$ip_address','','0',NULL),
(9600094,'$ip_address','','0',NULL),
(9600095,'$ip_address','','0',NULL),
(9600096,'$ip_address','','0',NULL),
(9600097,'$ip_address','','0',NULL),
(9600098,'$ip_address','','0',NULL),
(9600099,'$ip_address','','0',NULL),
(9600100,'$ip_address','','0',NULL),
(9600101,'$ip_address','','0',NULL),
(9600102,'$ip_address','','0',NULL),
(9600103,'$ip_address','','0',NULL),
(9600104,'$ip_address','','0',NULL),
(9600105,'$ip_address','','0',NULL),
(9600106,'$ip_address','','0',NULL),
(9600107,'$ip_address','','0',NULL),
(9600108,'$ip_address','','0',NULL),
(9600109,'$ip_address','','0',NULL),
(9600110,'$ip_address','','0',NULL),
(9600111,'$ip_address','','0',NULL),
(9600112,'$ip_address','','0',NULL),
(9600113,'$ip_address','','0',NULL),
(9600114,'$ip_address','','0',NULL),
(9600115,'$ip_address','','0',NULL),
(9600116,'$ip_address','','0',NULL),
(9600117,'$ip_address','','0',NULL),
(9600118,'$ip_address','','0',NULL),
(9600119,'$ip_address','','0',NULL),
(9600120,'$ip_address','','0',NULL),
(9600121,'$ip_address','','0',NULL),
(9600122,'$ip_address','','0',NULL),
(9600123,'$ip_address','','0',NULL),
(9600124,'$ip_address','','0',NULL),
(9600125,'$ip_address','','0',NULL),
(9600126,'$ip_address','','0',NULL),
(9600127,'$ip_address','','0',NULL),
(9600128,'$ip_address','','0',NULL),
(9600129,'$ip_address','','0',NULL),
(9600130,'$ip_address','','0',NULL),
(9600131,'$ip_address','','0',NULL),
(9600132,'$ip_address','','0',NULL),
(9600133,'$ip_address','','0',NULL),
(9600134,'$ip_address','','0',NULL),
(9600135,'$ip_address','','0',NULL),
(9600136,'$ip_address','','0',NULL),
(9600137,'$ip_address','','0',NULL),
(9600138,'$ip_address','','0',NULL),
(9600139,'$ip_address','','0',NULL),
(9600140,'$ip_address','','0',NULL),
(9600141,'$ip_address','','0',NULL),
(9600142,'$ip_address','','0',NULL),
(9600143,'$ip_address','','0',NULL),
(9600144,'$ip_address','','0',NULL),
(9600145,'$ip_address','','0',NULL),
(9600146,'$ip_address','','0',NULL),
(9600147,'$ip_address','','0',NULL),
(9600148,'$ip_address','','0',NULL),
(9600149,'$ip_address','','0',NULL),
(9600150,'$ip_address','','0',NULL),
(9600151,'$ip_address','','0',NULL),
(9600152,'$ip_address','','0',NULL),
(9600153,'$ip_address','','0',NULL),
(9600154,'$ip_address','','0',NULL),
(9600155,'$ip_address','','0',NULL),
(9600156,'$ip_address','','0',NULL),
(9600157,'$ip_address','','0',NULL),
(9600158,'$ip_address','','0',NULL),
(9600159,'$ip_address','','0',NULL),
(9600160,'$ip_address','','0',NULL),
(9600161,'$ip_address','','0',NULL),
(9600162,'$ip_address','','0',NULL),
(9600163,'$ip_address','','0',NULL),
(9600164,'$ip_address','','0',NULL),
(9600165,'$ip_address','','0',NULL),
(9600166,'$ip_address','','0',NULL),
(9600167,'$ip_address','','0',NULL),
(9600168,'$ip_address','','0',NULL),
(9600169,'$ip_address','','0',NULL),
(9600170,'$ip_address','','0',NULL),
(9600171,'$ip_address','','0',NULL),
(9600172,'$ip_address','','0',NULL),
(9600173,'$ip_address','','0',NULL),
(9600174,'$ip_address','','0',NULL),
(9600175,'$ip_address','','0',NULL),
(9600176,'$ip_address','','0',NULL),
(9600177,'$ip_address','','0',NULL),
(9600178,'$ip_address','','0',NULL),
(9600179,'$ip_address','','0',NULL),
(9600180,'$ip_address','','0',NULL),
(9600181,'$ip_address','','0',NULL),
(9600182,'$ip_address','','0',NULL),
(9600183,'$ip_address','','0',NULL),
(9600184,'$ip_address','','0',NULL),
(9600185,'$ip_address','','0',NULL),
(9600186,'$ip_address','','0',NULL),
(9600187,'$ip_address','','0',NULL),
(9600188,'$ip_address','','0',NULL),
(9600189,'$ip_address','','0',NULL),
(9600190,'$ip_address','','0',NULL),
(9600191,'$ip_address','','0',NULL),
(9600192,'$ip_address','','0',NULL),
(9600193,'$ip_address','','0',NULL),
(9600194,'$ip_address','','0',NULL),
(9600195,'$ip_address','','0',NULL),
(9600196,'$ip_address','','0',NULL),
(9600197,'$ip_address','','0',NULL),
(9600198,'$ip_address','','0',NULL),
(9600199,'$ip_address','','0',NULL),
(9600200,'$ip_address','','0',NULL),
(9600201,'$ip_address','','0',NULL),
(9600202,'$ip_address','','0',NULL),
(9600203,'$ip_address','','0',NULL),
(9600204,'$ip_address','','0',NULL),
(9600205,'$ip_address','','0',NULL),
(9600206,'$ip_address','','0',NULL),
(9600207,'$ip_address','','0',NULL),
(9600208,'$ip_address','','0',NULL),
(9600209,'$ip_address','','0',NULL),
(9600210,'$ip_address','','0',NULL),
(9600211,'$ip_address','','0',NULL),
(9600212,'$ip_address','','0',NULL),
(9600213,'$ip_address','','0',NULL),
(9600214,'$ip_address','','0',NULL),
(9600215,'$ip_address','','0',NULL),
(9600216,'$ip_address','','0',NULL),
(9600217,'$ip_address','','0',NULL),
(9600218,'$ip_address','','0',NULL),
(9600219,'$ip_address','','0',NULL),
(9600220,'$ip_address','','0',NULL),
(9600221,'$ip_address','','0',NULL),
(9600222,'$ip_address','','0',NULL),
(9600223,'$ip_address','','0',NULL),
(9600224,'$ip_address','','0',NULL),
(9600225,'$ip_address','','0',NULL),
(9600226,'$ip_address','','0',NULL),
(9600227,'$ip_address','','0',NULL),
(9600228,'$ip_address','','0',NULL),
(9600229,'$ip_address','','0',NULL),
(9600230,'$ip_address','','0',NULL),
(9600231,'$ip_address','','0',NULL),
(9600232,'$ip_address','','0',NULL),
(9600233,'$ip_address','','0',NULL),
(9600234,'$ip_address','','0',NULL),
(9600235,'$ip_address','','0',NULL),
(9600236,'$ip_address','','0',NULL),
(9600237,'$ip_address','','0',NULL),
(9600238,'$ip_address','','0',NULL),
(9600239,'$ip_address','','0',NULL),
(9600240,'$ip_address','','0',NULL),
(9600241,'$ip_address','','0',NULL),
(9600242,'$ip_address','','0',NULL),
(9600243,'$ip_address','','0',NULL),
(9600244,'$ip_address','','0',NULL),
(9600245,'$ip_address','','0',NULL),
(9600246,'$ip_address','','0',NULL),
(9600247,'$ip_address','','0',NULL),
(9600248,'$ip_address','','0',NULL),
(9600249,'$ip_address','','0',NULL),
(9600250,'$ip_address','','0',NULL),
(9600251,'$ip_address','','0',NULL),
(9600252,'$ip_address','','0',NULL),
(9600253,'$ip_address','','0',NULL),
(9600254,'$ip_address','','0',NULL),
(9600255,'$ip_address','','0',NULL),
(9600256,'$ip_address','','0',NULL),
(9600257,'$ip_address','','0',NULL),
(9600258,'$ip_address','','0',NULL),
(9600259,'$ip_address','','0',NULL),
(9600260,'$ip_address','','0',NULL),
(9600261,'$ip_address','','0',NULL),
(9600262,'$ip_address','','0',NULL),
(9600263,'$ip_address','','0',NULL),
(9600264,'$ip_address','','0',NULL),
(9600265,'$ip_address','','0',NULL),
(9600266,'$ip_address','','0',NULL),
(9600267,'$ip_address','','0',NULL),
(9600268,'$ip_address','','0',NULL),
(9600269,'$ip_address','','0',NULL),
(9600270,'$ip_address','','0',NULL),
(9600271,'$ip_address','','0',NULL),
(9600272,'$ip_address','','0',NULL),
(9600273,'$ip_address','','0',NULL),
(9600274,'$ip_address','','0',NULL),
(9600275,'$ip_address','','0',NULL),
(9600276,'$ip_address','','0',NULL),
(9600277,'$ip_address','','0',NULL),
(9600278,'$ip_address','','0',NULL),
(9600279,'$ip_address','','0',NULL),
(9600280,'$ip_address','','0',NULL),
(9600281,'$ip_address','','0',NULL),
(9600282,'$ip_address','','0',NULL),
(9600283,'$ip_address','','0',NULL),
(9600284,'$ip_address','','0',NULL),
(9600285,'$ip_address','','0',NULL),
(9600286,'$ip_address','','0',NULL),
(9600287,'$ip_address','','0',NULL),
(9600288,'$ip_address','','0',NULL),
(9600289,'$ip_address','','0',NULL),
(9600290,'$ip_address','','0',NULL),
(9600291,'$ip_address','','0',NULL),
(9600292,'$ip_address','','0',NULL),
(9600293,'$ip_address','','0',NULL),
(9600294,'$ip_address','','0',NULL),
(9600295,'$ip_address','','0',NULL),
(9600296,'$ip_address','','0',NULL),
(9600297,'$ip_address','','0',NULL),
(9600298,'$ip_address','','0',NULL),
(9600299,'$ip_address','','0',NULL);"

echo "Populate AREA CODES"
/usr/share/astguiclient/ADMIN_area_code_populate.pl
echo "Replace OLD IP. You need to Enter your Current IP here"
/usr/share/astguiclient/ADMIN_update_server_ip.pl --old-server_ip=10.10.10.15 --server_ip=$ip_address --auto

perl install.pl --no-prompt

# Install Crontab
sudo cat <<CRONTAB > /root/crontab-file
## Asterisk start fix
@reboot sleep 15 && /usr/share/astguiclient/start_asterisk_boot.pl

### Audio Sync hourly
* 1 * * * /usr/share/astguiclient/ADMIN_audio_store_sync.pl --upload --quiet

### Daily Backups ###
0 2 * * * /usr/share/astguiclient/ADMIN_backup.pl

###certbot renew
51 23 1 * * /usr/bin/systemctl stop firewalld
52 23 1 * * /usr/bin/certbot renew
53 23 1 * * /usr/bin/systemctl start firewalld
54 23 1 * * /usr/bin/systemctl restart httpd

### recording mixing/compressing/ftping scripts
#0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * * /usr/share/astguiclient/AST_CRON_audio_1_move_mix.pl
0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * * /usr/share/astguiclient/AST_CRON_audio_1_move_mix.pl --MIX
0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * * /usr/share/astguiclient/AST_CRON_audio_1_move_VDonly.pl
1,4,7,10,13,16,19,22,25,28,31,34,37,40,43,46,49,52,55,58 * * * * /usr/share/astguiclient/AST_CRON_audio_2_compress.pl --MP3 --HTTPS
#2,5,8,11,14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,59 * * * * /usr/share/astguiclient/AST_CRON_audio_3_ftp.pl --MP3

### keepalive script for astguiclient processes
* * * * * /usr/share/astguiclient/ADMIN_keepalive_ALL.pl --cu3way

### kill Hangup script for Asterisk updaters
* * * * * /usr/share/astguiclient/AST_manager_kill_hung_congested.pl

### updater for voicemail
* * * * * /usr/share/astguiclient/AST_vm_update.pl

### updater for conference validator
* * * * * /usr/share/astguiclient/AST_conf_update.pl

### flush queue DB table every hour for entries older than 1 hour
11 * * * * /usr/share/astguiclient/AST_flush_DBqueue.pl -q

### fix the vicidial_agent_log once every hour and the full day run at night
33 * * * * /usr/share/astguiclient/AST_cleanup_agent_log.pl
50 0 * * * /usr/share/astguiclient/AST_cleanup_agent_log.pl --last-24hours

## uncomment below if using QueueMetrics
#*/5 * * * * /usr/share/astguiclient/AST_cleanup_agent_log.pl --only-qm-live-call-check

## uncomment below if using Vtiger
#1 1 * * * /usr/share/astguiclient/Vtiger_optimize_all_tables.pl --quiet

### updater for VICIDIAL hopper
* * * * * /usr/share/astguiclient/AST_VDhopper.pl -q

### adjust the GMT offset for the leads in the vicidial_list table
1 1,7 * * * /usr/share/astguiclient/ADMIN_adjust_GMTnow_on_leads.pl --debug

### reset several temporary-info tables in the database
2 1 * * * /usr/share/astguiclient/AST_reset_mysql_vars.pl

### optimize the database tables within the asterisk database
3 1 * * * /usr/share/astguiclient/AST_DB_optimize.pl

## adjust time on the server with ntp
#30 * * * * /usr/sbin/ntpdate -u pool.ntp.org 2>/dev/null 1>&amp;2

### VICIDIAL agent time log weekly and daily summary report generation
2 0 * * 0 /usr/share/astguiclient/AST_agent_week.pl
22 0 * * * /usr/share/astguiclient/AST_agent_day.pl

### VICIDIAL campaign export scripts (OPTIONAL)
#32 0 * * * /usr/share/astguiclient/AST_VDsales_export.pl
#42 0 * * * /usr/share/astguiclient/AST_sourceID_summary_export.pl

### remove old recordings
#24 0 * * * /usr/bin/find /var/spool/asterisk/monitorDONE -maxdepth 2 -type f -mtime +7 -print | xargs rm -f
#26 1 * * * /usr/bin/find /var/spool/asterisk/monitorDONE/MP3 -maxdepth 2 -type f -mtime +65 -print | xargs rm -f
#25 1 * * * /usr/bin/find /var/spool/asterisk/monitorDONE/FTP -maxdepth 2 -type f -mtime +1 -print | xargs rm -f
24 1 * * * /usr/bin/find /var/spool/asterisk/monitorDONE/ORIG -maxdepth 2 -type f -mtime +1 -print | xargs rm -f

### roll logs monthly on high-volume dialing systems
30 1 1 * * /usr/share/astguiclient/ADMIN_archive_log_tables.pl --DAYS=45

### remove old vicidial logs and asterisk logs more than 2 days old
28 0 * * * /usr/bin/find /var/log/astguiclient -maxdepth 1 -type f -mtime +2 -print | xargs rm -f
29 0 * * * /usr/bin/find /var/log/asterisk -maxdepth 3 -type f -mtime +2 -print | xargs rm -f
30 0 * * * /usr/bin/find / -maxdepth 1 -name "screenlog.0*" -mtime +4 -print | xargs rm -f

### cleanup of the scheduled callback records
25 0 * * * /usr/share/astguiclient/AST_DB_dead_cb_purge.pl --purge-non-cb -q

### GMT adjust script - uncomment to enable
#45 0 * * * /usr/share/astguiclient/ADMIN_adjust_GMTnow_on_leads.pl --list-settings

### Dialer Inventory Report
1 7 * * * /usr/share/astguiclient/AST_dialer_inventory_snapshot.pl -q --override-24hours

### inbound email parser
* * * * * /usr/share/astguiclient/AST_inbound_email_parser.pl

### Daily Reboot
#30 6 * * * /sbin/reboot

######TILTIX GARBAGE FILES DELETE
#00 22 * * * root cd /tmp/ && find . -name '*TILTXtmp*' -type f -delete

### Dynportal
@reboot /usr/bin/VB-firewall --whitelist=ViciWhite --dynamic --quiet
* * * * * /usr/bin/VB-firewall --whitelist=ViciWhite --dynamic --quiet
* * * * * sleep 10; /usr/bin/VB-firewall --white --dynamic --quiet
* * * * * sleep 20; /usr/bin/VB-firewall --white --dynamic --quiet
* * * * * sleep 30; /usr/bin/VB-firewall --white --dynamic --quiet
* * * * * sleep 40; /usr/bin/VB-firewall --white --dynamic --quiet
* * * * * sleep 50; /usr/bin/VB-firewall --white --dynamic --quiet
CRONTAB


crontab -l

# Install rc.local
sudo cat <<EOF > /etc/rc.d/rc.local
#
# OPTIONAL enable ip_relay(for same-machine trunking and blind monitoring)
/usr/share/astguiclient/ip_relay/relay_control start 2>/dev/null 1>&2

# Disable console blanking and powersaving
/usr/bin/setterm -blank
/usr/bin/setterm -powersave off
/usr/bin/setterm -powerdown

### start up the MySQL server
systemctl start mariadb.service

### start up the apache web server
systemctl start httpd.service

### roll the Asterisk logs upon reboot
/usr/share/astguiclient/ADMIN_restart_roll_logs.pl

### clear the server-related records from the database
/usr/share/astguiclient/AST_reset_mysql_vars.pl

### load dahdi drivers
modprobe dahdi
modprobe dahdi_dummy

/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

### sleep for 20 seconds before launching Asterisk

sleep 20

### start up asterisk
/usr/share/astguiclient/start_asterisk_boot.pl

exit 0
EOF

sudo cat <<EOF > /lib/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.d/rc.local Compatibility

[Service]
Type=oneshot
ExecStart=/etc/rc.d/rc.local start
TimeoutSec=0
StandardInput=tty
RemainAfterExit=yes

[Install]
 WantedBy=multi-user.target
EOF

sudo chmod +x /etc/rc.d/rc.local
sudo chmod 644 /lib/systemd/system/rc-local.service

sudo systemctl daemon-reload
sudo systemctl enable rc-local.service
sudo systemctl start rc-local.service

## Fix ip_relay
cd /usr/src/astguiclient/trunk/extras/ip_relay/
unzip ip_relay_1.1.112705.zip
cd ip_relay_1.1/src/unix/
make
cp ip_relay ip_relay2
mv -f ip_relay /usr/bin/
mv -f ip_relay2 /usr/local/bin/ip_relay

cd /usr/lib64/asterisk/modules
wget http://asterisk.hosting.lv/bin/codec_g729-ast160-gcc4-glibc-x86_64-core2-sse4.so
mv codec_g729-ast160-gcc4-glibc-x86_64-core2-sse4.so codec_g729.so
chmod 777 codec_g729.so

## Install Sounds

cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-wav-current.tar.gz

#Place the audio files in their proper places:
cd /var/lib/asterisk/sounds
tar -zxf /usr/src/asterisk-core-sounds-en-gsm-current.tar.gz
tar -zxf /usr/src/asterisk-core-sounds-en-ulaw-current.tar.gz
tar -zxf /usr/src/asterisk-core-sounds-en-wav-current.tar.gz
tar -zxf /usr/src/asterisk-extra-sounds-en-gsm-current.tar.gz
tar -zxf /usr/src/asterisk-extra-sounds-en-ulaw-current.tar.gz
tar -zxf /usr/src/asterisk-extra-sounds-en-wav-current.tar.gz

mkdir /var/lib/asterisk/mohmp3
mkdir /var/lib/asterisk/quiet-mp3
ln -s /var/lib/asterisk/mohmp3 /var/lib/asterisk/default

cd /var/lib/asterisk/mohmp3
tar -zxf /usr/src/asterisk-moh-opsound-gsm-current.tar.gz
tar -zxf /usr/src/asterisk-moh-opsound-ulaw-current.tar.gz
tar -zxf /usr/src/asterisk-moh-opsound-wav-current.tar.gz
rm -f CHANGES*
rm -f LICENSE*
rm -f CREDITS*

cd /var/lib/asterisk/moh
rm -f CHANGES*
rm -f LICENSE*
rm -f CREDITS*

cd /var/lib/asterisk/sounds
rm -f CHANGES*
rm -f LICENSE*
rm -f CREDITS*

yum -y install sox

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
/usr/bin/systemctl status httpd --no-pager
/usr/bin/systemctl status firewalld --no-pager
/usr/share/astguiclient/AST_VDhopper.pl -q
/usr/bin/screen -ls
/usr/sbin/dahdi_cfg -v
/usr/sbin/asterisk -V
EOF

## fstab entry
tee -a /etc/fstab <<EOF
none /var/spool/asterisk/monitor tmpfs nodev,nosuid,noexec,nodiratime,size=2G 0 0
EOF

cat <<WELCOME>> /var/www/html/index.html
<META HTTP-EQUIV=REFRESH CONTENT="1; URL=/vicidial/welcome.php">
Please Hold while I redirect you!
WELCOME

cd /usr/src/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/confbridges.sh
chmod +x confbridges.sh
./confbridges.sh

sudo sed -i 's/SERVER_EXTERNAL_IP/192.168.1.15/' /etc/asterisk/pjsip.conf
sudo sed -i 's/SERVER_EXTERNAL_IP/192.168.1.15/' /etc/asterisk/pjsip.conf

chkconfig asterisk off

## Install firewall
yum -y install firewalld

systemctl enable firewalld
systemctl start firewalld 

# Firewall configuration
firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=446/tcp
firewall-cmd --permanent --zone=public --add-port=8089/tcp
firewall-cmd --permanent --zone=public --add-port=8088/tcp
firewall-cmd --permanent --zone=public --add-port=5060-5061/tcp
firewall-cmd --permanent --zone=public --add-port=5060-5061/udp
firewall-cmd --permanent --zone=public --add-port=10000-20000/udp
firewall-cmd --reload

systemctl restart firrewalld

chmod -R 777 /var/spool/asterisk/monitorDONE
chown -R apache:apache /var/spool/asterisk/monitorDONE

echo "Admin Interface:"
echo "Access http://$ip_address/vicidial/admin.php (username:6666, password:1234)"

echo "Agent Interface:"
echo "http://$ip_address/agc/vicidial.php (enter agent username and password which you have created through admin interface)"

read -p 'Press Enter to Reboot:'
echo "Restarting AlmaLinux"
reboot
