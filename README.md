Alma Rocky 9 Asterisk 18
```

hostnamectl set-hostname xxxxxx.xxxxx.xxx
### Use YOUR SubDomain

vi /etc/hosts
##Change domain name for actual server ip (xxx.xxx.xxx.xxx   complete domain name    subdomain only)

timedatectl set-timezone Africa/Kigali

yum check-update
yum update -y
yum -y install epel-release
yum update -y
yum install git -y
yum install -y kernel*

#Disable SELINUX
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config    

cd /usr/src/
git clone https://github.com/hrmuwanika/vicidial-install-scripts.git

reboot

````
  Reboot Before running this script

## Install VICIDIAL scripts

```
cd /usr/src/vicidial-install-scripts
chmod +x alma-rocky9-ast18.sh
./alma-rocky9-ast18.sh
```

