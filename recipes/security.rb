# Load information about the current server from the servers data bag
local_server = data_bag_item('servers', node[:hostname])

# Load the MySQL root user data bag item
root_user = data_bag_item('database_users', node[:olyn_percona][:user][:root][:data_bag_item])

# Set the MySQL root password
execute 'set_root_password' do
  command "mysql -u root -p'#{node[:olyn_percona][:seed_file][:config][:initial_password]}' -e \"" \
            "ALTER USER 'root'@'localhost' IDENTIFIED BY '#{root_user[:password]}'; " \
            'FLUSH PRIVILEGES;"' \
          ' && ' \
          "touch #{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.set_root_password.lock"
  user 'root'
  group 'root'
  sensitive true
  creates "#{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.set_root_password.lock"
  only_if { local_server[:bootstrapper] }
  action :run
end

# Secure MySQL from basic things
execute 'mysql_secure_script' do
  command "mysql -u root -p\"#{root_user[:password]}\" -e \"" \
            "DELETE FROM mysql.user WHERE User=''; " \
            "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); " \
            'DROP DATABASE IF EXISTS test; ' \
            "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; " \
            'FLUSH PRIVILEGES;"' \
          ' && ' \
          "touch #{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.mysql_secure_script.lock"
  user 'root'
  group 'root'
  sensitive true
  creates "#{Chef::Config[:olyn_application_data_path]}/lock/olyn_percona.mysql_secure_script.lock"
  only_if { local_server[:bootstrapper] }
  action :run
end
