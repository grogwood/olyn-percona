# Percona repo
default[:olyn_percona][:release_manager][:url] = 'https://repo.percona.com/apt/percona-release_latest.generic_all.deb'
default[:olyn_percona][:release_manager][:path] = "#{Chef::Config[:file_cache_path]}/percona-release_latest.generic_all.deb"

# The repo to add using the release manager
default[:olyn_percona][:release_manager][:repo][:name] = 'pxc-80'

# Percona packages
default[:olyn_percona][:application][:package][:base]   = 'percona-xtradb-cluster'
default[:olyn_percona][:application][:package][:server] = 'percona-xtradb-cluster-server'

# Percona packages data bag item
default[:olyn_percona][:application][:package][:data_bag_item] = 'percona'

# Config file locations on the server
default[:olyn_percona][:config][:mysqld][:path] = '/etc/mysql/mysql.conf.d/mysqld.cnf'
default[:olyn_percona][:config][:client][:path] = '/etc/mysql/mysql.conf.d/client.cnf'

# Default collation and character set
default[:olyn_percona][:config][:client][:character_set] = 'utf8mb4'
default[:olyn_percona][:config][:client][:collation] = 'utf8mb4_unicode_520_ci'

# Root user data bag item
default[:olyn_percona][:user][:root][:data_bag_item] = 'root'

# The name of Percona seed file for debconf
default[:olyn_percona][:seed_file][:template] = 'percona.seed.erb'

# Default password for root during install
default[:olyn_percona][:seed_file][:config][:initial_password] = 'TemporaryPW'

# Use legacy authentication method for 5.x backwards compatibility?
default[:olyn_percona][:seed_file][:config][:use_legacy_auth] = false

# Port data bag items
default[:olyn_percona][:port][:group][:data_bag_item] = 'percona_group'
default[:olyn_percona][:port][:mysql][:data_bag_item] = 'percona_mysql'
default[:olyn_percona][:port][:ist][:data_bag_item]   = 'percona_ist'
default[:olyn_percona][:port][:sst][:data_bag_item]   = 'percona_sst'

# SSL Certificate data bag items
default[:olyn_percona][:ssl][:server][:data_bag_item] = 'percona_server'
default[:olyn_percona][:ssl][:client][:data_bag_item] = 'percona_client'
