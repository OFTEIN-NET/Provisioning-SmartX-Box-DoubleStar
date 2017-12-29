#!/bin/bash
#
# Name          : bdstar_loop_detector_trial1.sh
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
#START_TIME=$(date)

function looping {
#Check Boxes for Looping Problem
LOOPING_GIST=`ssh $BOX_USER@Smartx-BPlus-GIST 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`
LOOPING_MYREN=`ssh $BOX_USER@Smartx-BPlus-MYREN 'tail -n 5 /var/log/openvswitch/ovs-vswitchd.log | grep poll_loop'`

if [ "${LOOPING_GIST:-null}" = null ] && [ "${LOOPING_MYREN:-null}" = null ]; then
        echo -e "No Looping Issue Found"
        sleep 30
        looping
else
        START_TIME=$(date)
        mail -a "Content-type: text/html;" -s "[$START_TIME] Looping Issue Found" user@smartx.kr <<< "Recovery Process is Running Now."
        echo -e "Recovery Start Time: $START_TIME"
        echo -e "Looping Issue Found"

        #Get the Active OVS VM Information
        echo -e "***************************************************************************"
        ACTIVE_VM=`ssh $BOX_USER@Smartx-BPlus-GIST 'virsh list --all | grep ovs-vm | grep running' | awk '{print $2}'`
        #ACTIVE_VM="ovs-vm2"
        echo -e "Active VM : $ACTIVE_VM"

        #Find StandBy VM
        if [ "$ACTIVE_VM" == "ovs-vm1" ]; then
                STANDBY_VM="ovs-vm2"
        elif [ "$ACTIVE_VM" == "ovs-vm2" ]; then
                STANDBY_VM="ovs-vm1"
        else
                STANDBY_VM="ovs-vm1"
        fi
        echo -e "Stand By VM : $STANDBY_VM"
        echo -e "==========================================================================\n\n"

        # Stop Active VM and OpenvSwitch Process in all sites
        echo -e "**************************************************************************"
        for Box in $SITES
        do
                echo -e "Stop OVS-VM and OVS Process in : Smartx-BPlus-$Box"
                ssh $BOX_USER@Smartx-BPlus-$Box 'virsh destroy '$ACTIVE_VM' && service openvswitch-switch stop && echo '$STANDBY_VM' > /etc/libvirt/active-vm'
        done
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

        # Start OVS-VM in all sites
        echo -e "*************************************************************************"
        for Box in $SITES
        do
                echo -e "Starting OVS-VM in Site : Smartx-BPlus-$Box"
                ssh $BOX_USER@Smartx-BPlus-$Box 'virsh start '$STANDBY_VM
                sleep 5
                for num in {1..5}
                do
                        ssh $BOX_USER@Smartx-BPlus-$Box 'brctl delif virbr0 vnet'$num
                done
        done
        echo -e "=========================================================================\n\n"

        # Start OpenvSwitch Process in all sites
        echo -e "*************************************************************************"
        for Box in $SITES
        do
                ssh $BOX_USER@Smartx-BPlus-$Box 'service openvswitch-switch start'
                echo -e "OVS Started In: Smartx-BPlus-$Box"
        done
        sleep 10
        echo -e "=========================================================================\n\n"

        #Add Operator Flows
        echo -e "*************************************************************************"
        echo -e "Add Operator Flows and Rename Devices"
        if [ "$STANDBY_VM" == "ovs-vm1" ]; then
                /home/netcs/SmartX-BStar/assign_flow_for_admin_bstar_vm1.sh $OPS_CONTROLLER
        else
                /home/netcs/SmartX-BStar/assign_flow_for_admin_bstar_vm2.sh $OPS_CONTROLLER
        fi
        /home/netcs/SmartX-BStar/assign_ovs_name.sh $OPS_CONTROLLER
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
        sleep 20
        
		#Add Developer Flows
        echo -e "*************************************************************************"
        echo -e "Add Developer Flows"
        if [ "$STANDBY_VM" == "ovs-vm1" ]; then
                /home/netcs/SmartX-BStar/assign_flow_for_user_bstar_vm1.sh $DEV_CONTROLLER
        else
                /home/netcs/SmartX-BStar/assign_flow_for_user_bstar_vm2.sh $DEV_CONTROLLER
        fi
        
		/home/netcs/SmartX-BStar/assign_ovs_name.sh $DEV_CONTROLLER
        echo -e "=========================================================================\n\n"

        for Box in $SITES
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