#!/usr/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if ! command -v smartctl &> /dev/null
then
    echo "To continue install smartmontools"
    exit
fi

if ! command -v git &> /dev/null
then
    echo "To continue install git"
    exit
fi

echo "(optional) Install sg3-utils if you need to monitor hardware RAIDs."
echo "(optional) Install nvme-cli if you need to monitor NVMe devices."

zbx_user=$(cat /etc/passwd | grep zabbix | tr ':' ' ' | awk '{print $1}')
zbx_group=$(cat /etc/group | grep zabbix | tr ':' ' ' | awk '{print $1}')

mkdir -p tmp
git clone https://github.com/v-zhuravlev/zbx-smartctl tmp

mkdir -p /etc/sudoers.d/
sed -i "s/Defaults:zabbix/Defaults:${zbx_user}/g" tmp/sudoers_zabbix_smartctl
sed -i "s/zabbix ALL/${zbx_user} ALL/g" tmp/sudoers_zabbix_smartctl
cp tmp/sudoers_zabbix_smartctl /etc/sudoers.d/
chmod 440 /etc/sudoers.d/sudoers_zabbix_smartctl

mkdir -p /etc/zabbix/zabbix_agentd.d
cp tmp/zabbix_smartctl.conf /etc/zabbix/zabbix_agentd.d/
chown -R $zbx_user:$zbx_group /etc/zabbix/zabbix_agentd.d

if egrep -i "^Include=" /etc/zabbix/zabbix_agentd.conf; then
    sed -i "s|^Include=.*|Include=/etc/zabbix/zabbix_agentd.d/*.conf|g" /etc/zabbix/zabbix_agentd.conf
  else
    echo -e "# Include zabbix_agentd.d" >> /etc/zabbix/zabbix_agentd.conf
    echo -e "Include=/etc/zabbix/zabbix_agentd.d/*.conf" >> /etc/zabbix/zabbix_agentd.conf
fi

mkdir -p /etc/zabbix/scripts
cp tmp/discovery-scripts/nix/smartctl-disks-discovery.pl /etc/zabbix/scripts/
chown -R $zbx_user:$zbx_group /etc/zabbix/scripts
chmod u+x /etc/zabbix/scripts/smartctl-disks-discovery.pl


if ! command -v service &> /dev/null
then
    service zabbix-agent restart
fi

if ! command -v systemctl &> /dev/null
then
    systemctl restart zabbix-agent
fi

rm -rf tmp
