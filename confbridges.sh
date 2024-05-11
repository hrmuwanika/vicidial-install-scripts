#!/bin/sh

echo "Upgrade Asterisk 18 to use ConfBridges"


cd /usr/src/
rm -rf vicidial-install-scripts
git clone https://github.com/hrmuwanika/vicidial-install-scripts.git

cd /usr/src/vicidial-install-scripts/
yes | cp -rf extensions.conf /etc/asterisk/extensions.conf
mv confbridge-vicidial.conf /etc/asterisk/

tee -a /etc/asterisk/confbridge.conf <<EOF

#include confbridge-vicidial.conf
EOF

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

tee -a /etc/asterisk/manager.conf <<EOF

[confcron]
secret = 1234
read = command,reporting
write = command,reporting

eventfilter=Event: Meetme
eventfilter=Event: Confbridge
EOF



sed -i 's|vicidial_conferences|vicidial_confbridges|g' /var/www/html/vicidial/non_agent_api.php



