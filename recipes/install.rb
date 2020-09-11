# Include the services recipe
include_recipe 'olyn_percona::services'

# Load information about the current server from the servers data bag
local_server = data_bag_item('servers', node[:hostname])

# Load the mysql root user data bag item
percona_root_user = data_bag_item('percona_users', node[:olyn_percona][:users][:root][:data_bag_item])

# Remove MariaDB if it was on the server
package 'mariadb-common' do
  action :nothing
end

# Remove MySQL if it was on the server
package 'mysql-common' do
  action :nothing
end

# Remove AppArmor if it was on the server
package 'apparmor' do
  action :nothing
end

# Install the base percona package unattended
package node[:olyn_percona][:packages][:base] do
  options '-q -y'
  response_file node[:olyn_percona][:seed_file]
  response_file_variables(
    package:       node[:olyn_percona][:packages][:server],
    root_password: node[:olyn_percona][:users][:root][:initial_password]
  )
  action :install
  notifies :remove, 'package[mariadb-common]', :before
  notifies :remove, 'package[mysql-common]', :before
  notifies :remove, 'package[apparmor]', :before
end

# Set the MySQL root password
execute 'set_percona_root_password' do
  command "mysql -u root -p'#{node[:olyn_percona][:users][:root][:initial_password]}' -e \"" \
            "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{percona_root_user[:password]}'; " \
            'FLUSH PRIVILEGES;"' \
          ' && ' \
          "touch #{Chef::Config[:file_cache_path]}/percona.root_password.lock"
  user 'root'
  group 'root'
  sensitive true
  action :run
  creates "#{Chef::Config[:file_cache_path]}/percona.root_password.lock"
end

# One time lock file for percona member init (stops mysql on non-bootsrappers)
file "#{Chef::Config[:file_cache_path]}/percona.member.init.lock" do
  action :create_if_missing
  only_if { !local_server[:options][:percona][:bootstrapper] }
  notifies :stop, 'service[mysql]', :immediately
  notifies :start, 'service[mysql]', :delayed
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

# Percona MySqlD config file that holds WSREP settings
template node[:olyn_percona][:config_files][:mysqld_file] do
  source 'mysqld.cnf.erb'
  mode 0644
  owner 'root'
  group 'root'
  variables(
    local_server: local_server,
    cluster_ips:  cluster_ips,
    certificates: { server: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl_certificates][:server_data_bag_item]),
                    client: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl_certificates][:client_data_bag_item]) },
    ports:        { group: data_bag_item('ports', node[:olyn_percona][:ports][:group][:data_bag_item]),
                    mysql: data_bag_item('ports', node[:olyn_percona][:ports][:mysql][:data_bag_item]),
                    sst:   data_bag_item('ports', node[:olyn_percona][:ports][:sst][:data_bag_item]),
                    ist:   data_bag_item('ports', node[:olyn_percona][:ports][:ist][:data_bag_item]) }
  )
  sensitive true
end

# MySQL client config file
template node[:olyn_percona][:config_files][:client_file] do
  source 'client.cnf.erb'
  mode 0644
  owner 'root'
  group 'root'
  variables(
    certificates: { server: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl_certificates][:server_data_bag_item]),
                    client: data_bag_item('ssl_certificates', node[:olyn_percona][:ssl_certificates][:client_data_bag_item]) },
    ports:        {
      mysql: data_bag_item('ports', node[:olyn_percona][:ports][:mysql][:data_bag_item])
    }
  )
end
