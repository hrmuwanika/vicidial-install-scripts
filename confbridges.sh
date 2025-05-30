#!/bin/sh

echo "Upgrade Asterisk 18 to use ConfBridges"

cd /usr/src/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/confbridge-vicidial.conf
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/extensions.conf

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
load = chan_dahdi.so
load = res_timing_dahdi.so
load = res_timing_timerfd.so
load = res_timing_pthread.so
load = res_http_websocket.so
EOF

sed -i 's|vicidial_conferences|vicidial_confbridges|g' /var/www/html/vicidial/non_agent_api.php

asterisk -rx "core reload"
asterisk -rx "module unload chan_dahdi.so"
asterisk -rx "module load chan_dahdi.so"

