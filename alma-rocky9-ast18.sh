#!/bin/sh

echo "================================================"
echo "Vicidial installation on AlmaLinux/RockyLinux"
echo "================================================"

# Update Server
yum check-update
dnf -y update

yum -y install nano git wget tar epel-release chkconfig libedit-devel
yum -y groupinstall 'Development Tools'
yum -y update
yum -y install kernel-devel-`uname -r`

# Disable SELINUX
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config  
setenforce 0
sestatus

# Disable password authentication
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

# Set the timezone
timedatectl set-timezone Africa/Kigali

export LC_ALL=C

# Updating YUM Repos
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum -y install http://rpms.remirepo.net/enterprise/remi-release-9.rpm
yum -y install yum-utils

dnf -y module enable php:remi-7.4
dnf -y module enable mariadb:10.5 
dnf -y install dnf-plugins-core

yum -y install php screen php-mcrypt subversion php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-opcache  
yum -y install wget git unzip make patch gcc gcc-c++ subversion php-devel php-gd gd-devel readline-devel php-mbstring php-mcrypt
yum -y install php-imap php-mysqli php-odbc php-pear php-xml php-xmlrpc curl curl-devel perl-libwww-perl ImageMagick

yum -y install httpd
systemctl enable httpd.service
systemctl start httpd.service

yum -y install mariadb-server mariadb-devel mariadb-libs
systemctl enable mariadb.service
systemctl start mariadb.service

yum -y install newt-devel libxml2* libxml2-devel kernel-devel sqlite-devel libuuid-devel sox sendmail htop iftop perl-File-Which kernel-devel
yum -y install libss7 libss7* libopen* unzip perl-Term-ReadLine-Gnu libpcap libpcap-devel libnet ncurses ncurses-devel mutt glibc.i686 python3-certbot-apache --skip-broken
yum -y install openssl openssl-devel unixODBC libtool-ltdl speex libtool automake autoconf mod_ssl certbot uuid*
yum -y copr enable irontec/sngrep 
dnf -y install sngrep 

dnf --enablerepo=crb install libsrtp libsrtp-devel libsrtp-devel -y
dnf config-manager --set-enabled crb
yum -y install elfutils-libelf-devel

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
max_input_vars = 20000

EOF

systemctl restart httpd

yum -y install chkconfig atop mytop
yum -y install libedit-devel speex* postfix dovecot s-nail roundcubemail inxi

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

systemctl restart httpd.service
systemctl restart mariadb.service

# Install Perl Modules
echo "Install Perl"
yum -y install perl-CPAN 
yum -y install perl-YAML 
yum -y install perl-CPAN-DistnameInfo 
yum -y install perl-libwww-perl 
yum -y install perl-DBI 
yum -y install perl-DBD-MariaDB
yum -y install perl-GD 
yum -y install perl-Env 
yum -y install perl-Term-ReadLine-Gnu 
yum -y install perl-SelfLoader 
yum -y install perl-open.noarch 

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
cpanm readline
cpanm Bundle::CPAN
cpanm DBI
cpanm DBI::MariaDB
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

# CPM install
cd /usr/src/vicidial-install-scripts
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

# Installation of eaccelerator
cd /usr/src/
wget https://github.com/eaccelerator/eaccelerator/zipball/master -O eaccelerator.zip
unzip eaccelerator.zip
cd eaccelerator-*
export PHP_PREFIX=”/usr”
$PHP_PREFIX/bin/phpize
./configure –enable-eaccelerator=shared –with-php-config=$PHP_PREFIX/bin/php-config
make

cd /usr/src
wget https://github.com/cisco/libsrtp/archive/v2.1.0.tar.gz
tar xfv v2.1.0.tar.gz
cd libsrtp-2.1.0
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install
ldconfig

# Install and compile libpri
mkdir /usr/src/asterisk
cd /usr/src/asterisk
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1-current.tar.gz
tar -zxvf libpri-1-current.tar.gz
cd libpri-1.*
make
make install

# Install Dahdi
echo "Install Dahdi"
ln -sf /usr/lib/modules/$(uname -r)/vmlinux.xz /boot/
cd /etc/include
wget https://dialer.one/newt.h

cd /usr/src/
mkdir dahdi-linux-complete-3.2.0+3.2.0
cd dahdi-linux-complete-3.2.0+3.2.0
wget https://dialer.one/dahdi-alma9.zip
unzip dahdi-alma9.zip
yum in newt* -y

sudo sed -i 's|(netdev, \&wc->napi, \&wctc4xxp_poll, 64);|(netdev, \&wc->napi, \&wctc4xxp_poll);|g' /usr/src/dahdi-linux-complete-3.2.0+3.2.0/linux/drivers/dahdi/wctc4xxp/base.c
sudo sed -i 's|<linux/pci-aspm.h>|<linux/pci.h>|g' /usr/src/dahdi-linux-complete-3.2.0+3.2.0/linux/include/dahdi/kernel.h

make clean
make
make install
make config

yum -y install dahdi-tools-libs

cd tools
make clean
make
make install
make config

cp /etc/dahdi/system.conf.sample /etc/dahdi/system.conf
modprobe dahdi
modprobe dahdi_dummy
/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

# Install Asterisk
mkdir /usr/src/asterisk
cd /usr/src/asterisk
wget http://download.vicidial.com/required-apps/asterisk-18.21.0-vici.tar.gz
tar -zxvf asterisk-18.21.0-vici.tar.gz
rm asterisk-18.21.0-vici.tar.gz
cd /usr/src/asterisk/asterisk-18*/

# Download the mp3 decoder library
./contrib/scripts/get_mp3_source.sh

# Ensure all dependencies are resolved
./contrib/scripts/install_prereq install

# Run the configure script to satisfy build dependencies
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

adduser asterisk --disabled-password --gecos "Asterisk User"

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

touch /usr/lib/systemd/system/asterisk.service
cat > /usr/lib/systemd/system/asterisk.service << EOF
[Unit]
Description=Asterisk PBX and telephony daemon.
#After=network.target
#include these if asterisk need to bind to a specific IP (other than 0.0.0.0)
Wants=network-online.target
After=network-online.target network.target

[Service]
Type=simple
Environment=HOME=/var/lib/asterisk
WorkingDirectory=/var/lib/asterisk
ExecStart=/usr/sbin/asterisk -mqf -C /etc/asterisk/asterisk.conf
ExecReload=/usr/sbin/asterisk -rx 'core reload'
ExecStop=/usr/sbin/asterisk -rx 'core stop now'

LimitCORE=infinity
Restart=always
RestartSec=4

# Prevent duplication of logs with color codes to /var/log/messages
StandardOutput=null

PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl disable asterisk.service
systemctl enable asterisk.service
systemctl start asterisk
systemctl status asterisk

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
update servers set asterisk_version='18.21.0';
quit
MYSQLCREOF

# update the timezone
cp /usr/share/zoneinfo/Africa/Kigali /etc/localtime

read -p 'Press Enter to continue: '
echo 'Continuing...'

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
cat > /root/crontab-file <<CRONTAB

###Audio Sync hourly
* 1 * * * /usr/share/astguiclient/ADMIN_audio_store_sync.pl --upload --quiet

### Daily Backups ###
0 2 * * * /usr/share/astguiclient/ADMIN_backup.pl

###certbot renew
51 23 1 * * /usr/bin/systemctl stop firewalld
52 23 1 * * /usr/sbin/certbot renew
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

###### TILTIX GARBAGE FILES DELETE
#00 22 * * * root cd /tmp/ && find . -name '*TILTXtmp*' -type f -delete

CRONTAB

crontab -l

# Install rc.local
cat > /etc/rc.d/rc.local <<EOF

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

chmod +x /etc/rc.d/rc.local

# add rc-local as a service - thx to ras
cat > /etc/systemd/system/rc-local.service <<EOF
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

#systemctl enable rc-local
#systemctl start rc-local

# Firewall
yum -y install firewalld
systemctl start firewalld 
systemctl enable firewalld

# Firewall configuration
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=5060-5061/udp --permanent
firewall-cmd --zone=public --add-port=5060-5061/tcp --permanent
firewall-cmd --zone=public --add-port=10000-20000/udp --permanent
firewall-cmd --reload

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

tee -a /etc/httpd/conf/httpd.conf <<EOF

CustomLog /dev/null common

Alias /RECORDINGS/MP3 "/var/spool/asterisk/monitorDONE/MP3/"

<Directory "/var/spool/asterisk/monitorDONE/MP3/">
    Options Indexes MultiViews
    AllowOverride None
    Require all granted
</Directory>
EOF

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
echo "Restarting AlmaLinux"

reboot

# Admin Interface:
# http://yourserverip/vicidial/admin.php (username:6666, password:1234)

# Agent Interface:
# http://yourserverip/agc/vicidial.php (enter agent username and password which you have created through admin interface)
