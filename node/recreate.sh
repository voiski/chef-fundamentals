#!/bin/sh
#
# Script to recreate the node machine
#
vagrant destroy
vagrant up
new_ip=$(vagrant ssh -c "ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//'")
ssh-keygen -R ${new_ip//[^([:alnum:]|\.)]/}
knife node delete node1
(cd ../chef-repo;knife bootstrap $new_ip --sudo -x vagrant -P vagrant -N "node1")
knife node run_list add node1 "role[webserver]"
vagrant ssh -c "sudo sed -i '$ a log_level :info' /etc/chef/client.rb"
vagrant ssh -c "sudo chef-client"
