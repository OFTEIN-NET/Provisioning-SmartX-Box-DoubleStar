#!/bin/bash
#
# Name          : bdstar_install_flows_for_demo_user.sh
# Description   : A script for Installing user flows using ODL REST API.
#
# Created by    : Muhammad Usman
# Version       : 0.1
# Last Update   : October, 2016
#

# Specific Parameter

PARAMETER=1
BOX_USER=
OVS_VM_USER=
OVS_VM1=
OVS_VM2=
# Check IP Address of the controller

if [ $# -ne $PARAMETER ]; then

        echo -e ""
        echo -e "Usage  : ./assign_flow_for_user2.sh [IP]\n"
        echo -e "Available option is: \n"
        echo -e "IP is Developer Controller IP address"
        exit 0
else

#GIST Box Start
ACTIVE_VM=`ssh $BOX_USER@Smartx-BPlus-GIST 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
echo -e ''
echo -e '******   GIST Flow Entries   ****** '
echo -e "Active VM : $ACTIVE_VM "
if [ $ACTIVE_VM = 'ovs-vm1' ]; then
        PORTS=`ssh OVS_VM_USER@$OVS_VM1 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        ID=`echo $PORTS | grep ID | awk '{print $3}' | cut -f 1 -d "("`
        PH=`echo $PORTS | grep PH | awk '{print $4}' | cut -f 1 -d "("`
        PKS=`echo $PORTS | grep PKS | awk '{print $5}' | cut -f 1 -d "("`

elif [ $ACTIVE_VM = 'ovs-vm2' ]; then
        PORTS=`ssh OVS_VM_USER@$OVS_VM2 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        ID=`echo $PORTS | grep ID | awk '{print $3}' | cut -f 1 -d "("`
        PH=`echo $PORTS | grep PH | awk '{print $4}' | cut -f 1 -d "("`
        PKS=`echo $PORTS | grep PKS | awk '{print $5}' | cut -f 1 -d "("`
else
        echo -e "No OVS-VM is Active at Moment";
fi

curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"GIST_1_1", "node": {"id":"11:11:11:11:11:11:11:11", "type":"OF"}, "ingressPort": '$ID', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:11/staticFlow/GIST_1_1
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"GIST_1_2", "node": {"id":"11:11:11:11:11:11:11:11", "type":"OF"}, "ingressPort": '$IN_PORT', "priority":"65535","actions":["OUTPUT='$ID,$PH,$PKS'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:11/staticFlow/GIST_1_2
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"GIST_1_3", "node": {"id":"11:11:11:11:11:11:11:11", "type":"OF"}, "ingressPort": '$PH', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:11/staticFlow/GIST_1_3
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"GIST_1_4", "node": {"id":"11:11:11:11:11:11:11:11", "type":"OF"}, "ingressPort": '$PKS', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:11/staticFlow/GIST_1_4
#GIST Box End

#MYREN Box
ACTIVE_VM=`ssh $BOX_USER@Smartx-BPlus-MYREN 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
echo -e ''
echo -e '******   MYREN Flow Entries   ****** '
if [ $ACTIVE_VM = 'ovs-vm1' ]; then
        PORTS=`ssh OVS_VM_USER@$OVS_VM1 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        ID=`echo $PORTS | grep ID | awk '{print $3}' | cut -f 1 -d "("`
        PH=`echo $PORTS | grep PH | awk '{print $4}' | cut -f 1 -d "("`
        PKS=`echo $PORTS | grep PKS | awk '{print $5}' | cut -f 1 -d "("`

elif [ $ACTIVE_VM = 'ovs-vm2' ]; then
        PORTS=`ssh $OVS_VM_USER@$OVS_VM2 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        ID=`echo $PORTS | grep ID | awk '{print $3}' | cut -f 1 -d "("`
        PH=`echo $PORTS | grep PH | awk '{print $4}' | cut -f 1 -d "("`
        PKS=`echo $PORTS | grep PKS | awk '{print $5}' | cut -f 1 -d "("`
else
        echo -e "No OVS-VM is Active at Moment";
fi
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"MYREN_1_1", "node": {"id":"11:11:11:11:11:11:11:31", "type":"OF"}, "ingressPort": '$ID', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:31/staticFlow/MYREN_1_1
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"MYREN_1_2", "node": {"id":"11:11:11:11:11:11:11:31", "type":"OF"}, "ingressPort": '$IN_PORT', "priority":"65535","actions":["OUTPUT='$ID,$PH,$PKS'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:31/staticFlow/MYREN_1_2
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"MYREN_1_3", "node": {"id":"11:11:11:11:11:11:11:31", "type":"OF"}, "ingressPort": '$PH', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:31/staticFlow/MYREN_1_3
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"MYREN_1_4", "node": {"id":"11:11:11:11:11:11:11:31", "type":"OF"}, "ingressPort": '$PKS', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:31/staticFlow/MYREN_1_4
#MYREN Box End

#ID Box Start
ACTIVE_VM=`ssh root@Smartx-BPlus-ID 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
echo -e ''
echo -e '******   ID Flow Entries   ****** '
if [ $ACTIVE_VM = 'ovs-vm1' ]; then
        PORTS=`ssh $BOX_USER@$OVS_VM1 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        GIST=`echo $PORTS | grep GIST | awk '{print $3}' | cut -f 1 -d "("`
        MYREN=`echo $PORTS | grep MYREN | awk '{print $4}' | cut -f 1 -d "("`
elif [ $ACTIVE_VM = 'ovs-vm2' ]; then
        PORTS=`ssh tein@$OVS_VM2 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        GIST=`echo $PORTS | grep GIST | awk '{print $3}' | cut -f 1 -d "("`
        MYREN=`echo $PORTS | grep MYREN | awk '{print $4}' | cut -f 1 -d "("`
else
        echo -e "No OVS-VM is Active at Moment";
fi
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"ID_1_1", "node": {"id":"11:11:11:11:11:11:11:41", "type":"OF"}, "ingressPort": '$GIST', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:41/staticFlow/ID_1_1
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"ID_1_2", "node": {"id":"11:11:11:11:11:11:11:41", "type":"OF"}, "ingressPort": '$IN_PORT', "priority":"65535","actions":["OUTPUT='$GIST,$MYREN'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:41/staticFlow/ID_1_2
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"ID_1_3", "node": {"id":"11:11:11:11:11:11:11:41", "type":"OF"}, "ingressPort": '$MYREN', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:41/staticFlow/ID_1_3
#ID Box End

# PH Box Start
ACTIVE_VM=`ssh $BOX_USER@Smartx-BPlus-PH 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
echo -e ''
echo -e '******   PH Flow Entries   ****** '
if [ $ACTIVE_VM = 'ovs-vm1' ]; then
        PORTS=`ssh tein@$OVS_VM1 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        GIST=`echo $PORTS | grep GIST | awk '{print $3}' | cut -f 1 -d "("`
        MYREN=`echo $PORTS | grep MYREN | awk '{print $4}' | cut -f 1 -d "("`
elif [ $ACTIVE_VM = 'ovs-vm2' ]; then
        PORTS=`ssh tein@$OVS_VM2 'sudo -S <<< netmedia ovs-ofctl show brdev | grep "("' | awk '{print $1}'`
        IN_PORT=`echo $PORTS | grep eth1 | awk '{print $2}' | cut -f 1 -d "("`
        GIST=`echo $PORTS | grep GIST | awk '{print $3}' | cut -f 1 -d "("`
        MYREN=`echo $PORTS | grep MYREN | awk '{print $4}' | cut -f 1 -d "("`
else
        echo -e "No OVS-VM is Active at Moment";
fi
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"PH_1_1", "node": {"id":"11:11:11:11:11:11:11:51", "type":"OF"}, "ingressPort": '$GIST', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:51/staticFlow/PH_1_1
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"PH_1_2", "node": {"id":"11:11:11:11:11:11:11:51", "type":"OF"}, "ingressPort": '$IN_PORT', "priority":"65535","actions":["OUTPUT='$GIST,$MYREN'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:51/staticFlow/PH_1_2
curl -u admin:admin -H 'Content-type: application/json' -X PUT -d '{"installInHw":"true", "name":"PH_1_3", "node": {"id":"11:11:11:11:11:11:11:51", "type":"OF"}, "ingressPort": '$MYREN', "priority":"65535","actions":["OUTPUT='$IN_PORT'"]}' http://$1:8080/controller/nb/v2/flowprogrammer/default/node/OF/11:11:11:11:11:11:11:51/staticFlow/PH_1_3
#PH Box End
fi