# Load information about the current server from the servers data bag
local_server = data_bag_item('servers', node[:hostname])

# Load the MySQL root user data bag item
root_user = data_bag_item('database_users', node[:olyn_percona][:users][:root][:data_bag_item])

# Set the MySQL root password
execute 'set_percona_root_password' do
  command "mysql -u root -p'#{node[:olyn_percona][:seed_file][:initial_password]}' -e \"" \
            "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{root_user[:password]}'; " \
            'FLUSH PRIVILEGES;"' \
          ' && ' \
          "touch #{Chef::Config[:file_cache_path]}/percona.root_password.lock"
  user 'root'
  group 'root'
  sensitive true
  action :run
  creates "#{Chef::Config[:file_cache_path]}/percona.root_password.lock"
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
          "touch #{Chef::Config[:file_cache_path]}/percona.sql.hardening.lock"
  creates "#{Chef::Config[:file_cache_path]}/percona.sql.hardening.lock"
  action :run
  only_if { local_server[:bootstrapper] }
  sensitive true
end
