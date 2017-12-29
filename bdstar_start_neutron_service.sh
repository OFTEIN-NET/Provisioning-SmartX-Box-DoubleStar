#!/bin/bash
#
# Name          : bdstar_start_neutron_service
# Description   : A script for starting OpenStack Neutron Services.
#
# Created by    : Muhammad Usman
# Version       : 0.1
# Last Update   : October, 2016
#

# Specific Parameter

su stack
python /usr/local/bin/neutron-openvswitch-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini > /dev/null 2>&1 &