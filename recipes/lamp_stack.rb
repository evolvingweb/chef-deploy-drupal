#
## Author:: Alex Dergachev
## Cookbook Name:: deploy_drupal
## Recipe:: lamp_stack
##
## Copyright 2012, Evolving Web Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
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
