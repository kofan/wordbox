# Author: Nickolay U. Kofanov
# Date: 2015-02-25

# Set mysql debian and replication passwords to the root one
node.default['mysql']['server_debian_password'] = node['mysql']['server_root_password'];
node.default['mysql']['server_repl_password'] = node['mysql']['server_root_password'];

include_recipe 'apache2'
include_recipe 'apache2::mpm_prefork'
include_recipe 'apache2::mod_php5'
include_recipe 'apache2::mod_ssl'
include_recipe 'mysql::server'
include_recipe 'mysql::ruby'
include_recipe 'php'
include_recipe 'rsync'

include_recipe 'wpbx::cli'
include_recipe 'wpbx::install'
include_recipe 'wpbx::tools'