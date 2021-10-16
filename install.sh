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

mkdir -p tmp
git clone https://github.com/v-zhuravlev/zbx-smartctl tmp

mkdir -p /etc/sudoers.d/
cp tmp/sudoers_zabbix_smartctl /etc/sudoers.d/
chmod 440 /etc/sudoers.d/sudoers_zabbix_smartctl

mkdir -p /etc/zabbix/zabbix_agentd.d
cp tmp/zabbix_smartctl.conf /etc/zabbix/zabbix_agentd.d/

mkdir -p /etc/zabbix/scripts
cp tmp/discovery-scripts/nix/smartctl-disks-discovery.pl /etc/zabbix/scripts/
chown zabbix:zabbix /etc/zabbix/scripts/smartctl-disks-discovery.pl
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
