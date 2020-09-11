# Include the main install recipe
include_recipe 'olyn_percona::install'

# Cluster bootstrap routines if applicable
include_recipe 'olyn_percona::bootstrap'

# Configure databases
include_recipe 'olyn_percona::databases'

# Configure users
include_recipe 'olyn_percona::users'
