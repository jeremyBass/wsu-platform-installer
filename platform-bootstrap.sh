#!/bin/bash

yum -y install unzip

mkdir -p /var/www
mkdir -p /srv/pillar

cd /tmp && rm -fr wsu-platform
cd /tmp && curl -o wsu-platform.zip -L https://github.com/washingtonstateuniversity/WSUWP-Platform/archive/master.zip
cd /tmp && unzip wsu-platform.zip
cd /tmp && mv WSUWP-Platform-master wsu-platform
cp -fr /tmp/wsu-platform/pillar /srv/pillar
cp -fr /tmp/wsu-platform/www /var/www

cd /tmp && rm -fr wsu-web
cd /tmp && curl -o wsu-web.zip -L https://github.com/washingtonstateuniversity/wsu-web-provisioner/archive/master.zip
cd /tmp && unzip wsu-web.zip
cd /tmp && mv WSU-Web-Provisioner-master wsu-web
cp -fr /tmp/wsu-web/provision/salt /srv/
cp /tmp/wsu-web/provision/salt/config/local.yum.conf /etc/yum.conf
rpm -Uvh --force http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sed -i 's/mirrorlist=https/mirrorlist=http/' /etc/yum.repos.d/epel.repo
yum -y update python
sh /tmp/wsu-web/provision/bootstrap_salt.sh -K stable
rm /etc/salt/minion.d/*.conf
rm /etc/salt/minion_id
echo "wsuwp-prod" > /etc/salt/minion_id
cp /tmp/wsu-web/provision/salt/minions/wsuwp.conf /etc/salt/minion.d/
salt-call --local --log-level=info --config-dir=/etc/salt state.highstate
