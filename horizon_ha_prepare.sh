node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then



sudo cp /vagrant/horizon.py /etc/openstack-dashboard/local_settings.py
sudo service apache2 restart
sudo service memcached restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo cp /vagrant/horizon.py /etc/openstack-dashboard/local_settings.py
sudo service apache2 restart
sudo service memcached restart
exit
EOF

# Get OpenStack Keystone OCF resource agent
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/memcached-ra /usr/lib/ocf/resource.d/openstack/memcached
sudo chmod 0755 *
cd ~

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
cd /usr/lib/ocf/resource.d
sudo mkdir -p openstack
cd openstack
sudo cp /vagrant/memcached-ra /usr/lib/ocf/resource.d/openstack/memcached
sudo chmod 0755 *
cd ~
exit
EOF

#Configure Pacemaker resources
sudo crm configure primitive p_apache2 ocf:heartbeat:apache params configfile="/etc/apache2/apache2.conf" op monitor interval="40s"
sudo crm configure primitive p_memcached ocf:openstack:memcached params pid="/var/run/memcached.pid" config="/etc/memcached.conf" op monitor interval="30s" timeout="30s"

sudo crm configure group g_openstack p_keystone p_glance-registry p_glance-api p_quantum-server p_quantum-metadata-agent p_quantum-l3-agent p_quantum-dhcp-agent p_quantum-plugin-linuxbridge-agent p_libvirt p_nova-api p_nova-cert p_nova-compute p_nova-conductor p_nova-consoleauth p_nova-novncproxy p_nova-scheduler p_iscsi p_cinder-api p_cinder-volume p_cinder-scheduler p_apache2 p_memcached meta target-role="Started"

#sudo drbdadm verify mysql

#Configure Colocation
#sudo crm configure colocation c_openstack_on_drbd inf: g_openstack ms_drbd_mysql:Master
#Configure order
#sudo crm configure order o_drbd_before_openstack inf: ms_drbd_mysql:promote g_mysql:start g_openstack:start

fi
