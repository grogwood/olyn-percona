# Percona repo
default[:olyn_percona][:release_manager][:url]  = 'https://repo.percona.com/apt/percona-release_latest.generic_all.deb'
default[:olyn_percona][:release_manager][:file] = "#{Chef::Config[:file_cache_path]}/percona-release_latest.generic_all.deb"
default[:olyn_percona][:release_manager][:repo] = 'pxc57'

# Percona packages
default[:olyn_percona][:packages][:base]   = 'percona-xtradb-cluster-57'
default[:olyn_percona][:packages][:server] = 'percona-xtradb-cluster-server-5.7'

# Percona packages data bag item
default[:olyn_percona][:percona_packages_data_bag_item] = 'percona'

# MySQL root user
default[:olyn_percona][:users][:root][:data_bag_item]    = 'percona_root'
default[:olyn_percona][:users][:root][:initial_password] = 'TemporaryPW'

# The name of Percona seed file for debconf
default[:olyn_percona][:seed_file] = 'percona.seed.erb'

# MySQL Percona SST user
default[:olyn_percona][:users][:sst][:data_bag_item] = 'percona_sst'

# Port data bag items
default[:olyn_percona][:ports][:group][:data_bag_item] = 'percona_group'
default[:olyn_percona][:ports][:mysql][:data_bag_item] = 'percona_mysql'
default[:olyn_percona][:ports][:ist][:data_bag_item]   = 'percona_ist'
default[:olyn_percona][:ports][:sst][:data_bag_item]   = 'percona_sst'

# SSL Certificate data bag items
default[:olyn_percona][:ssl_certificates][:server_data_bag_item] = 'percona_server'
default[:olyn_percona][:ssl_certificates][:client_data_bag_item] = 'percona_client'
