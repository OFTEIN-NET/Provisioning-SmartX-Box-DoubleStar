#!/bin/bash
#
# Name          : bdstar_ovs_vm_networking.sh
# Description   : A script for creating virsh networks.
#
# Created by    : Muhammad Usman
# Version       : 0.1
# Last Update   : October, 2016
#

# Specific Parameter

touch /etc/libvirt/ovs-bridge-brvlan.xml
touch /etc/libvirt/ovs-bridge-br-ex.xml
cd /etc/libvirt

echo -e "<network>\n <name>ovs-brvlan</name>\n <forward mode='bridge'/>\n <bridge name='brvlan'/>\n <virtualport type='openvswitch'/>\n</network>" >> ovs-bridge-brvlan.xml
echo -e "<network>\n <name>ovs-br-ex</name>\n <forward mode='bridge'/>\n <bridge name='br-ex'/>\n <virtualport type='openvswitch'/>\n</network>" >> ovs-bridge-br-ex.xml

virsh net-define ovs-bridge-brvlan.xml
virsh net-define ovs-bridge-br-ex.xml
virsh net-start ovs-brvlan
virsh net-start ovs-br-ex
virsh net-list
virsh net-autostart ovs-brvlan
virsh net-autostart ovs-br-ex