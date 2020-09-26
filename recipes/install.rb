# Include the services recipe
include_recipe 'olyn_percona::services'

# Load information about the current server from the servers data bag
local_server = data_bag_item('servers', node[:hostname])

# Remove MariaDB if it was on the server
package 'mariadb-common' do
  action :nothing
  subscribes :remove, "package[#{node[:olyn_percona][:application][:package][:base]}]", :before
end

# Remove MySQL if it was on the server
package 'mysql-common' do
  action :nothing
  subscribes :remove, "package[#{node[:olyn_percona][:application][:package][:base]}]", :before
end

# Remove AppArmor if it was on the server
package 'apparmor' do
  action :nothing
  subscribes :remove, "package[#{node[:olyn_percona][:application][:package][:base]}]", :before
end

# Install the base percona package unattended
package node[:olyn_percona][:application][:package][:base] do
  options '-q -y'
  response_file node[:olyn_percona][:seed_file][:template]
  response_file_variables(
    package:          node[:olyn_percona][:application][:package][:server],
    initial_password: node[:olyn_percona][:seed_file][:config][:initial_password],
    use_legacy_auth:  node[:olyn_percona][:seed_file][:config][:use_legacy_auth]
  )
  action :install
  notifies :stop, 'service[mysql]', :immediately
end

# An array of cluster IPs built from the server data bag
cluster_ips = []

# Loop through each server in the data bag to find cluster IPs
data_bag('servers').each do |server_item_name|

  # Load the data bag item
  server = data_bag_item('servers', server_item_name)

  # Skip this server if it isn't in the cluster or is the local server
  next if server[:cluster] != local_server[:cluster] || !local_server[:options][:percona][:member]

  # Add the IP to the cluster array
  cluster_ips << server[:ip]

end

# Percona MySQLd config file that holds WSREP settings
template node[:olyn_percona][:config][:mysqld][:path] do
  source 'mysqld.cnf.erb'
  mode 0644
  owner 'root'
  group 'root'
  variables(
    local_server: local_server,
    cluster_ips:  cluster_ips,
    certificates: { server: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl][:server][:data_bag_item]),
                    client: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl][:client][:data_bag_item]) },
    ports:        { group: data_bag_item('ports', node[:olyn_percona][:port][:group][:data_bag_item]),
                    mysql: data_bag_item('ports', node[:olyn_percona][:port][:mysql][:data_bag_item]),
                    sst:   data_bag_item('ports', node[:olyn_percona][:port][:sst][:data_bag_item]),
                    ist:   data_bag_item('ports', node[:olyn_percona][:port][:ist][:data_bag_item]) }
  )
  sensitive true
end

# MySQL client config file
template node[:olyn_percona][:config][:client][:path] do
  source 'client.cnf.erb'
  mode 0644
  owner 'root'
  group 'root'
  variables(
    character_set: node[:olyn_percona][:config][:client][:character_set],
    collation:     node[:olyn_percona][:config][:client][:collation],
    certificates: { server: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl][:server][:data_bag_item]),
                    client: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl][:client][:data_bag_item]) },
    ports:        { mysql: data_bag_item('ports', node[:olyn_percona][:port][:mysql][:data_bag_item]) }
  )
end
