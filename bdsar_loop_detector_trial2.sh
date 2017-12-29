#!/bin/bash
#
# Name          : bdstar_loop_detector_trial2.sh
# Description   : A script for loop checking and recovery.
#
# Created by    : Muhammad Usman
# Version       : 0.1
# Last Update   : October, 2016
#

# Specific Parameter

SITES="GIST MYREN ID PKS PH"
BOX_USER=

CONTROLLER_HOME="/home/netcs/opendaylight"
CONTROLLERS="controller1_IP controller2_IP"
CONTROLLER_USER=
CONTROLLER_PASSWORD=
OPS_CONTROLLER=
DEV_CONTROLLER=

FLOWVISOR=

function looping {
	#Get Active VM's
	ACTIVE_VM_GIST=`ssh $BOX_USER@Smartx-BPlus-GIST 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
	ACTIVE_VM_MYREN=`ssh $BOX_USER@Smartx-BPlus-MYREN 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
	#Find StandBy VM
	if [ "$ACTIVE_VM_GIST" == "ovs-vm1" ] && [ "$ACTIVE_VM_MYREN" == "ovs-vm1"  ]; then
		LOOPING_GIST=`ssh tein@GIST-OVS-VM1 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
		LOOPING_MYREN=`ssh tein@MYREN-OVS-VM1 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
	elif [ "$ACTIVE_VM_GIST" == "ovs-vm1" ] && [ "$ACTIVE_VM_MYREN" == "ovs-vm2"  ]; then
		LOOPING_GIST=`ssh tein@GIST-OVS-VM1 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
		LOOPING_MYREN=`ssh tein@MYREN-OVS-VM2 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
	elif [ "$ACTIVE_VM_GIST" == "ovs-vm2" ] && [ "$ACTIVE_VM_MYREN" == "ovs-vm1"  ]; then
		LOOPING_GIST=`ssh tein@GIST-OVS-VM2 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
		LOOPING_MYREN=`ssh tein@MYREN-OVS-VM1 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
	else
		LOOPING_GIST=`ssh tein@GIST-OVS-VM2 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
		LOOPING_MYREN=`ssh tein@MYREN-OVS-VM2 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
	fi

	if [ "${LOOPING_GIST:-null}" = null ] && [ "${LOOPING_MYREN:-null}" = null ]; then
       echo -e "No Looping Issue Found"
       sleep 30
       looping
	else
        START_TIME=$(date)
        mail -a "Content-type: text/html;" -s "[$START_TIME] Looping Issue Found" user@smartx.kr <<< "Recovery Process is Running Now."
        echo -e "Recovery Start Time: $START_TIME"
        echo -e "Looping Issue Found"

        #Find StandBy VM
        if [ "$ACTIVE_VM_GIST" == "ovs-vm1" ]; then
                STANDBY_VM_GIST="ovs-vm2"
        elif [ "$ACTIVE_VM_GIST" == "ovs-vm2" ]; then
                STANDBY_VM_GIST="ovs-vm1"
        else
                STANDBY_VM_GIST="ovs-vm1"
        fi
        if [ "$ACTIVE_VM_MYREN" == "ovs-vm1" ]; then
                STANDBY_VM_MYREN="ovs-vm2"
        elif [ "$ACTIVE_VM_MYREN" == "ovs-vm2" ]; then
                STANDBY_VM_MYREN="ovs-vm1"
        else
                STANDBY_VM_MYREN="ovs-vm1"
        fi

        # Stop Active VM and OpenvSwitch Process in all sites
        echo -e "**************************************************************************"
        ssh $BOX_USER@Smartx-BPlus-GIST 'virsh destroy '$ACTIVE_VM_GIST' && service openvswitch-switch stop && echo '$STANDBY_VM_GIST' > /etc/libvirt/active-vm'
        ssh $BOX_USER@Smartx-BPlus-MYREN 'virsh destroy '$ACTIVE_VM_MYREN' && service openvswitch-switch stop && echo '$STANDBY_VM_MYREN' > /etc/libvirt/active-vm'
        echo -e "=========================================================================\n\n"

        # Stop all CONTROLLERS (Operators + Developers)
        echo -e "*************************************************************************"
        PID=`ssh $CONTROLLER_USER@$OPS_CONTROLLER 'ps aux | grep opendaylight' | grep -v grep| awk '{print $2}'`
        ssh $CONTROLLER_USER@$OPS_CONTROLLER 'sudo -S <<< '$CONTROLLER_PASSWORD2' kill -9 '$PID
		
		PID=`ssh $CONTROLLER_USER@$DEV_CONTROLLER 'ps aux | grep opendaylight' | grep -v grep| awk '{print $2}'`
        ssh $CONTROLLER_USER@$OPS_CONTROLLER 'sudo -S <<< '$CONTROLLER_PASSWORD2' kill -9 '$PID
		
		for Box in $CONTROLLERS
        do
            echo -e "Stop SDN Controller At : $Box"
            PID=`ssh $CONTROLLER_USER@$Box 'ps aux | grep opendaylight' | grep -v grep| awk '{print $2}'`
            ssh $CONTROLLER_USER@$Box 'sudo -S <<< '$CONTROLLER_PASSWORD' kill -9 '$PID
        done

        echo -e "=========================================================================\n\n"
        sleep 10

        #Delete Flowspace & Restart Flowvisor
        echo -e "*************************************************************************"
        echo -e "Remove Flowspace & Restart Flowvisor At : $FLOWVISOR"
        ssh $CONTROLLER_USER@$FLOWVISOR 'fvctl-json --passwd-file=passwd remove-flowspace OPENSTACK-VLAN-101-FLOWSPACE && service flowvisor restart'
        echo -e "=========================================================================\n\n"

        # Start all SDN CONTROLLERS (Operators + Demo Developer)
        echo -e "*************************************************************************"
		ssh $CONTROLLER_USER@$OPS_CONTROLLER 'sudo -S <<< '$CONTROLLER_PASSWORD $CONTROLLER_HOME'/run.sh > /dev/null 2>&1 &'
		ssh $CONTROLLER_USER@$DEV_CONTROLLER 'sudo -S <<< '$CONTROLLER_PASSWORD $CONTROLLER_HOME'/run.sh > /dev/null 2>&1 &'
		
        for Box in $CONTROLLERS
        do
            echo -e "Start SDN Controller At : $Box"
            ssh $CONTROLLER_USER@$Box 'sudo -S <<< '$CONTROLLER_PASSWORD $CONTROLLER_HOME'/run.sh > /dev/null 2>&1 &'
        done
        echo -e "=========================================================================\n\n"
        sleep 10

        # Start OVS-VM in GIST & MYREN sites
        echo -e "*************************************************************************"
        echo -e "Starting OVS-VMs"
        ssh $BOX_USER@Smartx-BPlus-GIST 'virsh start '$STANDBY_VM_GIST
        ssh $BOX_USER@Smartx-BPlus-MYREN 'virsh start '$STANDBY_VM_MYREN
        sleep 60
        for num in {1..2}
        do
                ssh $BOX_USER@Smartx-BPlus-GIST 'brctl delif virbr0 vnet'$num
                ssh $BOX_USER@Smartx-BPlus-MYREN 'brctl delif virbr0 vnet'$num
        done
        echo -e "=========================================================================\n\n"

        # Start OpenvSwitch Process in GIST & MYREN sites
        echo -e "*************************************************************************"
        ssh $BOX_USER@Smartx-BPlus-GIST 'service openvswitch-switch start'
        ssh $BOX_USER@Smartx-BPlus-MYREN 'service openvswitch-switch start'
        sleep 60
        echo -e "=========================================================================\n\n"

        #Add Operator Flows
        echo -e "*************************************************************************"
        echo -e "Add Operator Flows and Rename Devices"
        /home/netcs/SmartX-BStar/flow_for_admin_bstar_vm1.sh $OPS_CONTROLLER
        sleep 60
        /home/netcs/SmartX-BStar/assign_ovs_name.sh $OPS_CONTROLLER
        sleep 60
        echo -e "=========================================================================\n\n"

        #Create Flowspace & Restart Flowvisor
        echo -e "*************************************************************************"
        echo -e "Create Flowspace"
        ssh $CONTROLLER_USER@$FLOWVISOR 'fvctl-json --passwd-file=passwd add-flowspace OPENSTACK-VLAN-101-FLOWSPACE 1111111111111111 10 dl_vlan=101 OPENSTACK-VLAN-101=4'
        ssh $CONTROLLER_USER@$FLOWVISOR 'fvctl-json --passwd-file=passwd add-flowspace OPENSTACK-VLAN-101-FLOWSPACE 1111111111111131 10 dl_vlan=101 OPENSTACK-VLAN-101=4'
        sleep 5
        ssh $CONTROLLER_USER@$FLOWVISOR 'fvctl-json --passwd-file=passwd add-flowspace OPENSTACK-VLAN-101-FLOWSPACE 1111111111111141 10 dl_vlan=101 OPENSTACK-VLAN-101=4'
        sleep 5
        ssh $CONTROLLER_USER@$FLOWVISOR 'fvctl-json --passwd-file=passwd add-flowspace OPENSTACK-VLAN-101-FLOWSPACE 1111111111111151 10 dl_vlan=101 OPENSTACK-VLAN-101=4'
        sleep 5
        ssh $CONTROLLER_USER@$FLOWVISOR 'fvctl-json --passwd-file=passwd add-flowspace OPENSTACK-VLAN-101-FLOWSPACE 1111111111111181 10 dl_vlan=101 OPENSTACK-VLAN-101=4'
        sleep 10
        ssh $CONTROLLER_USER@$FLOWVISOR 'service flowvisor restart'
        echo -e "=========================================================================\n\n"
        sleep 120

        #Add Developer Flows
        echo -e "*************************************************************************"
        echo -e "Add Developer Flows"
        /home/netcs/SmartX-BStar/flow_for_user_bstar.sh $DEV_CONTROLLER
        /home/netcs/SmartX-BStar/assign_ovs_name.sh $DEV_CONTROLLER
        echo -e "=========================================================================\n\n"

        #Start Neutron Service
        for Box in GIST MYREN
        do
                cat StartNeutronService.sh | ssh $BOX_USER@Smartx-BPlus-$Box > /dev/null 2>&1 &
                echo -e "Neutron Service Started In: Smartx-BPlus-$Box"
        done
        sleep 5

        #Total Execution Time of Script
        END_TIME=$(date)
        echo -e "End Time: $END_TIME"
        #EXECUTION_TIME=$((END_TIME-START_TIME))
        #echo -e "Time of Recovery: $EXECUTION_TIME"
        mail -a "Content-type: text/html;" -s "[$START_TIME] Looping Issue Recovery Report" user@smartx.kr <<< "Recovery Process Started at [$START_TIME] and Finished at [$END_TIME]. Now, you can access your SDN Controller."
        looping
	fi
}
looping