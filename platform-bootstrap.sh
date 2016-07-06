#!/bin/bash

#------
# function: to set up the stuff but only after things are ok
#-----------------------------------------------------
start(){
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
}


#-----------------------------------------------------------------------
# Add the keys to the server so you can get to github safely without
# need for a prompt which salt will not handle correctly
#-----------------------------------------------------------------------
yum install -y openssh-clients
[ -d ~/.ssh ] || mkdir -p ~/.ssh

# set up a config just incase to clear ssh warnings
if [ ! -z $(grep "Host *" ~/.ssh/config) ]; then
    echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n\tLogLevel ERROR" >> ~/.ssh/config
    echo "ssh warning suppression applied"
else
    echo "host * ssh warning suppression already applied"
fi
# just to be extra safe add github directly to them
touch ~/.ssh/known_hosts
ssh-keygen -R 192.30.252.128
ssh-keyscan -H 192.30.252.128 >> ~/.ssh/known_hosts
ssh-keygen -R 192.30.252.129
ssh-keyscan -H 192.30.252.129 >> ~/.ssh/known_hosts
ssh-keygen -R 192.30.252.130
ssh-keyscan -H 192.30.252.130 >> ~/.ssh/known_hosts
ssh-keygen -R 192.30.252.130
ssh-keyscan -H 192.30.252.131 >> ~/.ssh/known_hosts
ssh-keygen -R github.com
ssh-keyscan -H github.com >> ~/.ssh/known_hosts

yum  -y install unzip
yum -y kernel-headers --disableexcludes=all

mkdir -p /var/www

cd /tmp && rm -fr wsu-platform
cd /tmp && curl -o wsu-platform.zip -L https://github.com/washingtonstateuniversity/WSUWP-Platform/archive/master.zip
cd /tmp && unzip wsu-platform.zip
cd /tmp && mv WSUWP-Platform-master wsu-platform
cp -fr /tmp/wsu-platform/pillar /srv/
cp -fr /tmp/wsu-platform/www /var/

cd /
if [ ! -h /usr/sbin/gitploy ]; then
    curl  https://raw.githubusercontent.com/jeremyBass/gitploy/master/gitploy | sudo sh -s -- install
    [ -h /usr/sbin/gitploy ] || echoerr "gitploy failed install"
else
    gitploy update_gitploy
fi

gitploy init 2>&1 | grep -qi "already initialized" && echo ""
gitploy ls 2>&1 | grep -qi "platform" && gitploy up platform && start
gitploy ls 2>&1 | grep -qi "platform" || gitploy clone -b master platform git@github.com:jeremyBass/wsu-platform-parts.git && start


