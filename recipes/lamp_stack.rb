## Cookbook Name:: deploy-drupal
## Recipe:: lamp_stack
##
#

#force apt-get update
include_recipe "apt"

#probably need git
include_recipe "git"

#from apache2_mod_php

include_recipe "apache2"
include_recipe "apache2::mod_expires"
include_recipe "apache2::mod_php5"
include_recipe "apache2::mod_rewrite"

#from drupal
include_recipe "php"
include_recipe "php::module_curl"
include_recipe "php::module_gd"
include_recipe "php::module_mysql"
include_recipe "php::module_memcache"
# include_recipe "imagemagick"

include_recipe "memcached"
include_recipe "mysql::server"

#from drupal_dev
include_recipe "drush"

include_recipe "xhprof"
# include_recipe "drush_make"
# include_recipe "phpmyadmin" # TODO Cookbook needs testing!
# include_recipe "webgrind" # TODO Does this actually work?
# include_recipe "varnish"
