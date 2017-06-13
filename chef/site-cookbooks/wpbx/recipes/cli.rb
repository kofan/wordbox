# Author: Nickolay U. Kofanov
# Date: 2015-02-25

packages = %w{git zip unzip gcc perl make jq php5-mysql php5-intl php5-curl php5-gd}
binary = ::File.join(node[:wpbx][:cli][:dir], 'phar', 'wp-cli.phar')

packages.each do |pkg|
  package pkg do
    action [:install, :upgrade]
  end
end

git node[:wpbx][:cli][:dir] do
  repository "https://github.com/wp-cli/builds.git"
  action :sync
end

file binary do
  mode '0755'
  action :create
end

link node[:wpbx][:cli][:lnk] do
  to binary
end

directory '/home/vagrant/.wp-cli' do
  recursive true
  owner node[:wpbx][:user]
  group node[:wpbx][:group]
end

directory '/home/vagrant/.wp-cli/commands' do
  recursive true
  owner node[:wpbx][:user]
  group node[:wpbx][:group]
end

template '/home/vagrant/.wp-cli/cli.config.yml' do
  source "cli.config.yml.erb"
  owner node[:wpbx][:user]
  group node[:wpbx][:group]
  mode "0644"

  variables(
    :docroot_dir => File.join(node[:wpbx][:docroot_dir], node[:wpbx][:siteurl])
  )
end

git 'home/vagrant/.wp-cli/commands/dictator' do
  repository "https://github.com/danielbachhuber/dictator.git"
  user node[:wpbx][:user]
  group node[:wpbx][:group]
  action :sync
end
