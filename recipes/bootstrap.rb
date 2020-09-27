# Include the services recipe
include_recipe 'olyn_percona::services'

# Load information about the current server from the servers data bag
local_server = data_bag_item('servers', node[:hostname])

# Initiate/bootstrap the cluster
execute 'percona_bootstrap' do
  command 'systemctl start mysql@bootstrap.service' \
          ' && ' \
          "touch #{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.percona_bootstrap.lock"
  user 'root'
  group 'root'
  creates "#{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.percona_bootstrap.lock"
  action :run
  only_if { local_server[:bootstrapper] }
  notifies :stop, 'service[mysql]', :before
end

# Start MySQL non-bootsrappers
file "#{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.member_init.lock" do
  action :create_if_missing
  only_if { !local_server[:bootstrapper] }
  notifies :start, 'service[mysql]', :immediately
end
