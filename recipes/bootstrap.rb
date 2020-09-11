# Include the services recipe
include_recipe 'olyn_percona::services'

# Load information about the current server from the servers data bag
local_server = data_bag_item('servers', node[:hostname])

# Load the mysql root user data bag item
percona_root_user = data_bag_item('percona_users', node[:olyn_percona][:users][:root][:data_bag_item])

# Initiate/bootstrap the cluster
execute 'percona_bootstrap' do
  command 'systemctl start mysql@bootstrap.service' \
          ' && ' \
          "touch #{Chef::Config[:file_cache_path]}/percona.bootstrapper.init.lock"
  creates "#{Chef::Config[:file_cache_path]}/percona.bootstrapper.init.lock"
  action :run
  notifies :stop, 'service[mysql]', :before
  only_if { local_server[:options][:percona][:bootstrapper] }
end

# Load the percona SST backup user data bag item
percona_sst_user = data_bag_item('percona_users', node[:olyn_percona][:users][:sst][:data_bag_item])

# Create the percona SST user for replication
execute 'create_percona_sst_user' do
  command "mysql -u root -p\"#{percona_root_user[:password]}\" -e \"" \
            "CREATE USER IF NOT EXISTS '#{percona_sst_user[:username]}'@'#{percona_sst_user[:options]['host']}' IDENTIFIED BY '#{percona_sst_user[:password]}'; " \
            "GRANT #{percona_sst_user[:options]['privileges']} ON #{percona_sst_user[:options]['database']}.* TO '#{percona_sst_user[:username]}'@'#{percona_sst_user[:options]['host']}'; " \
            'FLUSH PRIVILEGES;"' \
          ' && ' \
          "touch #{Chef::Config[:file_cache_path]}/percona.user.#{percona_sst_user[:username]}.lock"
  creates "#{Chef::Config[:file_cache_path]}/percona.user.#{percona_sst_user[:username]}.lock"
  action :run
  only_if { local_server[:options][:percona][:bootstrapper] }
  sensitive true
end

# Secure MySQL from basic things
execute 'mysql_secure_script' do
  command "mysql -u root -p\"#{percona_root_user[:password]}\" -e \"" \
            "DELETE FROM mysql.user WHERE User=''; " \
            "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); " \
            'DROP DATABASE IF EXISTS test; ' \
            "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; " \
            'FLUSH PRIVILEGES;"' \
          ' && ' \
          "touch #{Chef::Config[:file_cache_path]}/percona.sql.hardening.lock"
  creates "#{Chef::Config[:file_cache_path]}/percona.sql.hardening.lock"
  action :run
  only_if { local_server[:options][:percona][:bootstrapper] }
  sensitive true
end
