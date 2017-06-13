# Author: Nickolay U. Kofanov
# Date: 2015-02-25

require 'shellwords'
docroot = ::File.join node[:wpbx][:docroot_dir], node[:wpbx][:siteurl]

# Add rules to the iptable service
iptables_rule "iptables.rules"

# Install worpdress if it doesn't exist
bash "wordpress-core-download" do
  user node[:wpbx][:user]
  group node[:wpbx][:group]

  code <<-EOS.gsub /\s+/m, ' '
    WP_CLI_CONFIG_PATH=#{Shellwords.shellescape(node[:wpbx][:cli][:cfg])} wp core download
    --path=#{docroot}
    --locale=#{Shellwords.shellescape(node[:wpbx][:locale])}
    --force
  EOS

  not_if { ::File.exists? File.join docroot, 'wp-login.php' }
end

bash "wordpress-core-config" do
  user node[:wpbx][:user]
  group node[:wpbx][:group]
  cwd File.join(docroot)

  code <<-CONFIG_CODE
    WP_CLI_CONFIG_PATH=#{Shellwords.shellescape(node[:wpbx][:cli][:cfg])} wp core config \\
    --dbhost=#{Shellwords.shellescape(node[:wpbx][:dbhost])} \\
    --dbname=#{Shellwords.shellescape(node[:wpbx][:dbname])} \\
    --dbuser=root \\
    --dbpass=#{node[:mysql][:server_root_password]} \\
    --dbprefix=#{Shellwords.shellescape(node[:wpbx][:dbprefix])} \\
    --locale=#{Shellwords.shellescape(node[:wpbx][:locale])} \\
    --extra-php <<EXTRA_PHP
  /** Additional configurations */
  define( 'WP_HOME', 'http://#{File.join(node[:wpbx][:host], node[:wpbx][:homeurl]).sub(/\/$/, '')}' );
  define( 'WP_SITEURL', 'http://#{File.join(node[:wpbx][:host], node[:wpbx][:siteurl]).sub(/\/$/, '')}' );
  define( 'WP_POST_REVISIONS', 3 );
  define( 'AUTOSAVE_INTERVAL', 300 );
  define( 'WP_DEBUG', #{node[:wpbx][:debug_mode]} );
  define( 'JETPACK_DEV_DEBUG', #{node[:wpbx][:debug_mode]} );
  define( 'FORCE_SSL_ADMIN', #{node[:wpbx][:force_ssl_admin]} );
  define( 'SAVEQUERIES', #{node[:wpbx][:savequeries]} );
EXTRA_PHP
  CONFIG_CODE

  not_if { File.exists? File.join(docroot, 'wp-config.php') }
end

# Create database if it does not exist
execute "wordpress-create-database" do
  command "/usr/bin/mysqladmin -uroot -p\"#{node[:mysql][:server_root_password]}\" create #{node[:wpbx][:dbname]}"

  not_if do
    # Make sure gem is detected if it was just installed earlier in this recipe
    require 'rubygems'
    Gem.clear_paths
    require 'mysql'

    m = Mysql.new "localhost", "root", node[:mysql][:server_root_password]
    m.list_dbs.include? node[:wpbx][:dbname]
  end

  notifies :run, "bash[wordpress-core-install]", :immediately
  notifies :run, "execute[wordpress-import-database]", :immediately
end

bash "wordpress-core-install" do
  user node[:wpbx][:user]
  group node[:wpbx][:group]
  cwd File.join(docroot)

  code <<-EOS.gsub /\s+/m, ' '
    WP_CLI_CONFIG_PATH=#{Shellwords.shellescape(node[:wpbx][:cli][:cfg])} wp core install
    --url=http://#{File.join(node[:wpbx][:host], node[:wpbx][:siteurl])}
    --title='#{node[:wpbx][:title]}'
    --admin_user=admin
    --admin_password=admin
    --admin_email=admin@#{File.join(node[:wpbx][:host])}
  EOS

  not_if { File.exists? File.join(docroot, 'dump.sql') }
  action :nothing
end

execute "wordpress-import-database" do
  command <<-EOS.gsub /\s+/m, ' '
     /usr/bin/mysql -uroot -p"#{node[:mysql][:server_root_password]}" -D#{node[:wpbx][:dbname]}
       < "#{File.join(docroot, 'dump.sql')}"
  EOS

  only_if { File.exists? File.join(docroot, 'dump.sql') }
  action :nothing
end

#
# Installs wordpress plugins
#
if node[:wpbx][:install_default_plugins]
  node[:wpbx][:default_plugins].each do |name, src|
    bash "wordpress-#{name}-install" do
      user node[:wpbx][:user]
      group node[:wpbx][:group]
      cwd File.join(docroot)

      code "WP_CLI_CONFIG_PATH=#{Shellwords.shellescape(node[:wpbx][:cli][:cfg])} wp plugin install #{Shellwords.shellescape(src)} --activate"
      not_if { File.exists? File.join(docroot, 'wp-content', 'plugins', name) }

      if src =~ /^https:\/\/github.com\//
        notifies :run, "ruby_block[wordpress-#{name}-rename]", :immediately
      end
    end

    ruby_block "wordpress-#{name}-rename" do
      block do
        plugins = ::File.join docroot, 'wp-content', 'plugins'
        branch = ::File.basename src, ".zip"

        ::File.rename File.join(plugins, name + '-' + branch), File.join(plugins, name)
      end

      action :nothing
    end
  end
end

#
# Change owner for document root
#
directory File.join(node[:wpbx][:docroot_dir], node[:wpbx][:homeurl]) do
  recursive true
  owner node[:wpbx][:user]
  group node[:wpbx][:group]
end

#
# Configure Apache virtual hosts
#
apache_site "000-default" do
  enable false
end

web_app node[:wpbx][:host] do
  template "apache.site.erb"
  docroot node[:wpbx][:docroot_dir]
  server_name node[:fqdn]
end

bash "create-ssl-keys" do
  user "root"
  group "root"
  cwd File.join(node[:apache][:dir], 'ssl')

  code <<-EOS
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -subj '/C=JP/ST=Wakayama/L=Kushimportoto/O=My Corporate/CN=#{node[:fqdn]}' -out server.csr
    openssl x509 -in server.csr -days 365 -req -signkey server.key > server.crt
  EOS

  not_if { File.size? File.join(node[:apache][:dir], 'ssl', 'server.crt') }
  notifies :restart, "service[apache2]"
end
