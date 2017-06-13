# Author: Nickolay U. Kofanov
# Date: 2015-02-25

default[:wpbx][:src_path]              = '/usr/local/share'
default[:wpbx][:makepot]               = '/usr/bin/php /usr/local/share/wp-i18n/makepot.php'
default[:wpbx][:bash_profile]          = '/home/vagrant/.bash_profile'
default[:wpbx][:ssh_config]            = '/home/vagrant/.ssh/config'
default[:wpbx][:lftp_config]           = '/etc/lftp.conf'

default[:wpbx][:i18ntools_repositry]   = 'http://i18n.svn.wordpress.org/tools/trunk/'
default[:wpbx][:i18ntools_revision]    = '56708'

default[:wpbx][:composer][:install]    = 'curl -sS https://getcomposer.org/installer | php'
default[:wpbx][:composer][:link]       = '/usr/local/bin/composer'
default[:wpbx][:composer][:home]       = '/home/vagrant/.composer'

default[:wpbx][:phpcs][:composer]       = 'squizlabs/php_codesniffer=*'
default[:wpbx][:phpcs][:sniffs]         = 'wpcs'
default[:wpbx][:phpcs][:alias]          = 'wpcs'

default[:wpbx][:user] = 'vagrant'
default[:wpbx][:group] = 'vagrant'

default[:wpbx][:cli][:dir] = '/usr/share/wp-cli'
default[:wpbx][:cli][:lnk] = '/usr/local/bin/wp'
default[:wpbx][:cli][:cfg] = '/home/vagrant/.wp-cli/config.yml'

default[:wpbx][:host] = "wordpress.local"
default[:wpbx][:title] = "WordPress Blog"
default[:wpbx][:homeurl] = ""
default[:wpbx][:siteurl] = ""
default[:wpbx][:docroot_dir] = "/var/www/wordpress"

default[:wpbx][:dbhost] = "localhost"
default[:wpbx][:dbname] = "wordpress"
default[:wpbx][:dbprefix] = "wp_"
default[:wpbx][:locale] = "en_US"
default[:wpbx][:install_default_plugins] = true
default[:wpbx][:default_plugins] = {
  'meta-box' => "meta-box",
  'wp-mail-smtp' => "wp-mail-smtp",
  'github-updater' => "https://github.com/afragen/github-updater/archive/master.zip",
  'wp-sync-db' => "https://github.com/wp-sync-db/wp-sync-db/archive/master.zip",
  'wp-sync-db-media-files' => "https://github.com/wp-sync-db/wp-sync-db-media-files/archive/master.zip"
}

default[:wpbx][:debug_mode] = false
default[:wpbx][:savequeries] = false
default[:wpbx][:force_ssl_admin] = false
