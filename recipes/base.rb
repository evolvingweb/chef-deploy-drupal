## Cookbook Name:: deploy-drupal
## Recipe:: base
##
#

base  = %w{ apt build-essential git curl vim }
apache= %w{ apache2 apache2::mod_rewrite apache2::mod_php5
                            apache2::mod_expires }
php   = %w{ php php::module_mysql php::module_memcache
                            php::module_gd php::module_curl}
mysql = %w{ mysql::server}
drupal= %w{ drush xhprof memcached }

pkgs = value_for_platform(
  [ "centos", "redhat", "fedora" ] => { #TODO needs testing
    "default" => %w{ pcre-devel php-mcrypt php-pecl-apc }
  },
  [ "debian", "ubuntu" ] => {
    "default" => %w{ libpcre3-dev php5-mcrypt php-apc }
  },
  "default" => %w{ libpcre3-dev php5-mcrypt php-apc }
)

# include all recipes
[base, apache, php, mysql, drupal].each do |group|
  group.each {|recipe| include_recipe recipe}
end

# install all packages
pkgs.each {|pkg| package ( pkg ) { action :install } }

# Install uploadprogress for better feedback during Drupal file uploads.
# php_pear LWRP is installed as part of the PHP cookbook
php_pear ("uploadprogress") { action :install }
