#!/bin/bash
#
# Copyright 2015 SmartX Collaboration (GIST NetCS). All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#
# Name          : bdstar_bridge_configuration.sh
# Description   : Script for installing nad Configuring OpenStack and SDN Open vSwitch Bridges
#
# Created by    : Muhammad Usman
# Version       : 0.1
# Last Update   : September, 2016
#

# Change Specific Parameter Before exection of script

SITE=

BRDEV_DPID=
BRCAP_DPID=

DP_IF=eth2
DP_GW=

devcontroller=
opscontroller=

OVSVM_IP=192.168.122.101
OVSVM_PASSWORD=

# Copy the source of OpenStack through DevStack for Juno Stable Release

start=$(date +"%s")
echo Installation Start at `date +"%r"`


# ADDING THE BRIDGE brdev brcap and common
# =============================================

echo "Configuring SDN Open vSwitch Bridges common configuration"
sleep 2

echo "Adding SDN bridge and patch ports"
sleep 2

# Add ovs-vm interface in brvlan
ovs-vsctl add-port brvlan vnet1

#Add ovs-vm interface in br-ex
sudo ovs-vsctl add-port br-ex vnet2

#Create Developer & Operator Bridges inside VM
ssh tein@$OVSVM_IP << EOSSH
sudo -S <<< $OVSVM_PASSWORD su
#create Routes Script
touch /home/tein/route.sh
sudo chmod +x /home/tein/route.sh

#Run route.sh at system startup
sudo sed -i '$i/home/tein/route.sh' /etc/rc.local

sudo ovs-vsctl add-br brdev
sudo ovs-vsctl add-br brcap

# Add patch port in bridge brdev inside vm
sudo ovs-vsctl add-port brdev eth1

if [ $SITE = "GIST" ]||[ $SITE = "MYREN" ]; then
#Add route entries 
echo "#!/bin/bash" >> route.sh

if [ $SITE = "GIST" ]; then
echo "sudo route add -host  gw $DP_GW dev $DP_IF #MYREN" >> route.sh
fi
if [ $SITE = "MYREN" ]; then
echo "sudo route add -net  gw $DP_GW dev $DP_IF #GIST" >> route.sh
fi

echo "sudo route add -net  gw $DP_GW dev $DP_IF #ID" >> route.sh
echo "sudo route add -net  gw $DP_GW dev $DP_IF #PH" >> route.sh
echo "sudo route add -net  gw $DP_GW dev $DP_IF #PKS" >> route.sh
sudo /home/tein/route.sh

# Add patch ports in developer bridge
echo "******************************************"
echo "        Adding Patch ports                "
echo "******************************************"
sudo ovs-vsctl add-port brdev ID
sudo ovs-vsctl set Interface ID type=patch
sudo ovs-vsctl set Interface ID options:peer=C_ID

sudo ovs-vsctl add-port brdev PH
sudo ovs-vsctl set Interface PH type=patch
sudo ovs-vsctl set Interface PH options:peer=C_PH

sudo ovs-vsctl add-port brdev PKS
sudo ovs-vsctl set Interface PKS type=patch
sudo ovs-vsctl set Interface PKS options:peer=C_PKS

# Add patch ports in operator bridge
sudo ovs-vsctl add-port brcap C_ID
sudo ovs-vsctl set Interface C_ID type=patch
sudo ovs-vsctl set Interface C_ID options:peer=ID

sudo ovs-vsctl add-port brcap C_PH
sudo ovs-vsctl set Interface C_PH type=patch
sudo ovs-vsctl set Interface C_PH options:peer=PH

sudo ovs-vsctl add-port brcap C_PKS
sudo ovs-vsctl set Interface C_PKS type=patch
sudo ovs-vsctl set Interface C_PKS options:peer=PKS

# Add VXLAN ports
echo "******************************************"
echo "           Add VXLAN ports                "
echo "******************************************"
sudo ovs-vsctl add-port brcap ovs_vxlan_ID
sudo ovs-vsctl set Interface ovs_vxlan_ID type=vxlan
sudo ovs-vsctl set Interface ovs_vxlan_ID options:remote_ip=

sudo ovs-vsctl add-port brcap ovs_vxlan_PH
sudo ovs-vsctl set Interface ovs_vxlan_PH type=vxlan
sudo ovs-vsctl set Interface ovs_vxlan_PH options:remote_ip=

sudo ovs-vsctl add-port brcap ovs_vxlan_PKS
sudo ovs-vsctl set Interface ovs_vxlan_PKS type=vxlan
sudo ovs-vsctl set Interface ovs_vxlan_PKS options:remote_ip=

echo "******************************************"
echo "Setting the Datapath ID and Controller Information"
echo "******************************************"
sleep 2


else
	#Add route entries 
	echo "#!/bin/bash" >> route.sh
	echo "sudo route add -net  gw $DP_GW dev $DP_IF #GIST" >> route.sh
	echo "sudo route add -host  gw $DP_GW dev $DP_IF #MYREN" >> route.sh
	sudo /home/tein/route.sh
	
	# Add patch ports in developer & Operator bridges
	echo "******************************************"
	echo "            Adding Patch ports            "
	echo "******************************************"
	sudo ovs-vsctl add-port brdev GIST
	sudo ovs-vsctl set Interface GIST type=patch
	sudo ovs-vsctl set Interface GIST options:peer=C_GIST

	sudo ovs-vsctl add-port brdev MYREN
	sudo ovs-vsctl set Interface MYREN type=patch
	sudo ovs-vsctl set Interface MYREN options:peer=C_MYREN

	sudo ovs-vsctl add-port brcap C_GIST
	sudo ovs-vsctl set Interface C_GIST type=patch
	sudo ovs-vsctl set Interface C_GIST options:peer=GIST

	sudo ovs-vsctl add-port brcap C_MYREN
	sudo ovs-vsctl set Interface C_MYREN type=patch
	sudo ovs-vsctl set Interface C_MYREN options:peer=MYREN

	echo "******************************************"
	echo "Route and Overlay Network to GIST & MYREN sites"
	echo "******************************************"
	# Add Routes
	#sudo route add -net  gw $DP_GW dev $DP_IF
	#sudo route add -host  gw $DP_GW dev $DP_IF

	# Add VXLAN ports
	sudo ovs-vsctl add-port brcap ovs_vxlan_GIST
	sudo ovs-vsctl set Interface ovs_vxlan_GIST type=vxlan
	sudo ovs-vsctl set Interface ovs_vxlan_GIST options:remote_ip=

	sudo ovs-vsctl add-port brcap ovs_vxlan_MYREN
	sudo ovs-vsctl set Interface ovs_vxlan_MYREN type=vxlan
	sudo ovs-vsctl set Interface ovs_vxlan_MYREN options:remote_ip=

	echo "Setting the Datapath ID and Controller Information"
	sleep 2

fi

# SET OpenFlow Version, DATAPATH ID AND CONTROLLER WITH FLOWVISOR
# =============================================
# Set OpenFlow Version
sudo ovs-vsctl set bridge brdev protocols=OpenFlow10
sudo ovs-vsctl set bridge brcap protocols=OpenFlow10

# Set datapath ID
sudo ovs-vsctl set bridge brdev other-config:datapath-id=$BRDEV_DPID
sudo ovs-vsctl set bridge brcap other-config:datapath-id=$BRCAP_DPID

# Set Controller
sudo ovs-vsctl set-controller brdev tcp:$devcontroller:6633
sudo ovs-vsctl set-controller brcap tcp:$opscontroller:6633
EOSSH

# Calculate the configuration time duration

stop=$(date +"%s")
echo Installation Finish at `date +"%r"`
diff=$(($stop-$start))
echo "$(($diff / 3600)) hours $(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."