# Grab the required Percona packages data bag item
percona_packages = data_bag_item('packages', node[:olyn_percona][:application][:package][:data_bag_item])

# Install all Percona packages in the data bag
percona_packages[:packages].each do |package|
  package package do
    action :install
  end
end

# Download the Percona release package
remote_file node[:olyn_percona][:release_manager][:path] do
  source node[:olyn_percona][:release_manager][:url]
  mode '0755'
  action :create_if_missing
end

# Install the Percona release manager package
dpkg_package 'percona_release_manager' do
  source node[:olyn_percona][:release_manager][:path]
  action :install
  notifies :run, 'execute[percona_release_manager_conf]', :immediately
end

# Set the Percona release manager to use the specified repo
execute 'percona_release_manager_conf' do
  command "percona-release setup #{node[:olyn_percona][:release_manager][:repo][:name]}"
  action :nothing
  notifies :run, 'execute[percona_apt_update]', :immediately
end

# Perform an APT update after adding Percona repos
execute 'percona_apt_update' do
  command 'apt-get update'
  action :nothing
end
