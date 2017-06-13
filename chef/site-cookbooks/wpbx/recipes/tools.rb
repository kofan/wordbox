# Author: Nickolay U. Kofanov
# Date: 2015-02-25

packages = %w{gettext subversion lftp sshpass}

packages.each do |pkg|
  package pkg do
    action [:install, :upgrade]
  end
end

#
# Set default ruby
#
rvm_default_ruby "ruby-2.1.4"

#
# Install wordmove https://github.com/welaika/wordmove
#
rvm_gem "wordmove" do
  action :install
  notifies :create, "cookbook_file[wordmove-1.2.0/sql_adapter.rb]", :immediately
end

# Fix for wordmove 1.2.0 version
cookbook_file "wordmove-1.2.0/sql_adapter.rb" do
  dest = '/var/lib/gems/1.9.1/gems/wordmove-1.2.0/lib/wordmove/sql_adapter.rb'

  path dest
  source "wordmove/sql_adapter.rb"
  only_if { ::File.exists? dest }
  mode 0755

  action :nothing
end

#
# Install xDebug php package
#
php_pear "xdebug" do
  action :install
  zend_extensions ['xdebug.so']
  directives(
    :remote_enable => "on",
    :remote_connect_back => "on",
    :idekey => "vagrant"
  )
end

%w{apache2 cgi cli}.each do |mod|
    link "/etc/php5/#{mod}/conf.d/xdebug.ini" do
      to "#{node['php']['ext_conf_dir']}/xdebug.ini"
    end
end


#
# Setup WordPress i18n Tools
#
subversion "Checkout WordPress i18n tools." do
  repository    node[:wpbx][:i18ntools_repositry]
  revision      node[:wpbx][:i18ntools_revision]
  destination   File.join(node[:wpbx][:src_path], 'wp-i18n');
  action        :sync
  user          "root"
  group         "root"
end

execute "echo 'alias makepot.php=\"#{node[:wpbx][:makepot]}\"' >> #{node[:wpbx][:bash_profile]}" do
  not_if "grep 'alias makepot.php' #{node[:wpbx][:bash_profile]}"
end

#
# Setup Composer
#
directory File.join(node[:wpbx][:src_path], 'composer') do
  recursive true
end

execute node[:wpbx][:composer][:install] do
  user  "root"
  group "root"
  cwd   File.join(node[:wpbx][:src_path], 'composer')
end

link node[:wpbx][:composer][:link] do
  to File.join(node[:wpbx][:src_path], 'composer/composer.phar')
end

directory node[:wpbx][:composer][:home] do
  user  "vagrant"
  group "vagrant"
  recursive true
end

#
# Setup PHP Code Sniffer
#
execute "phpcs-install" do
  user  "vagrant"
  group "vagrant"
  environment ({'COMPOSER_HOME' => node[:wpbx][:composer][:home]})
  command <<-EOH
    #{node[:wpbx][:composer][:link]} global require #{node[:wpbx][:phpcs][:composer]}
  EOH
end

directory File.join(node[:wpbx][:src_path], node[:wpbx][:phpcs][:sniffs]) do
  recursive true
end

git File.join(node[:wpbx][:src_path], node[:wpbx][:phpcs][:sniffs]) do
  repository "https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git"
  reference  "master"
  user "root"
  group "root"
  action :sync
end

execute "echo 'export PATH=~/.composer/vendor/bin:$PATH' >> #{node[:wpbx][:bash_profile]}" do
  not_if "grep 'export PATH=~/.composer/vendor/bin:$PATH' #{node[:wpbx][:bash_profile]}"
end

execute "phpcs-add-alias" do
  command <<-EOS
    echo 'alias #{node[:wpbx][:phpcs][:alias]}="phpcs -p -s -v --standard=WordPress-Core"' >> #{node[:wpbx][:bash_profile]}
  EOS
  not_if "grep 'alias #{node[:wpbx][:phpcs][:alias]}=' #{node[:wpbx][:bash_profile]}"
end

#
# Allow SSH connection to any host
#
execute "ssh-allow-hosts" do
  command <<-EOS
    echo "Host *\\nStrictHostKeyChecking no\\nUserKnownHostsFile=/dev/null" >> #{node[:wpbx][:ssh_config]}
  EOS

  not_if "grep 'UserKnownHostsFile=/dev/null' #{node[:wpbx][:ssh_config]}"
end

execute "lftp-allow-hosts" do
  command <<-EOS
    echo "\\nset ssl:verify-certificate off" >> #{node[:wpbx][:lftp_config]}
  EOS

  not_if "grep 'set ssl:verify-certificate off' #{node[:wpbx][:lftp_config]}"
end

execute "phpcs-set-config" do
  user  "vagrant"
  group "vagrant"
  command <<-EOS
    /home/vagrant/.composer/vendor/bin/phpcs --config-set installed_paths #{File.join(node[:wpbx][:src_path], node[:wpbx][:phpcs][:sniffs])}
  EOS
end

file node[:wpbx][:bash_profile] do
  owner 'vagrant'
  group 'vagrant'
end

file node[:wpbx][:ssh_config] do
  owner 'vagrant'
  group 'vagrant'
end

