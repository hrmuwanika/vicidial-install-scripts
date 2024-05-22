#!/bin/sh

echo "Upgrade Asterisk 20 to use ConfBridges"

cd /usr/src/
rm -rf vicidial-install-scripts
git clone https://github.com/hrmuwanika/vicidial-install-scripts.git
cd /usr/src/vicidial-install-scripts/

yes | cp -rf extensions.conf /etc/asterisk/extensions.conf
mv confbridge-vicidial.conf /etc/asterisk/

tee -a /etc/asterisk/pjsip.conf <<EOF

#include "pjsip_wizard-vicidial.conf"
EOF

tee -a /etc/asterisk/confbridge.conf <<EOF

#include confbridge-vicidial.conf
EOF

tee -a /etc/asterisk/manager.conf <<EOF

[confcron]
secret = 1234
read = command,reporting
write = command,reporting

eventfilter=Event: Meetme
eventfilter=Event: Confbridge
EOF

tee -a /etc/asterisk/modules.conf <<EOF

load = res_timing_dahdi.so
load = res_timing_timerfd.so

noload = res_timing_kqueue.so
noload = res_timing_pthread.so
EOF

sed -i 's|vicidial_conferences|vicidial_confbridges|g' /var/www/html/vicidial/non_agent_api.php

systemctl restart asterisk.service

