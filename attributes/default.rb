#
## Author:: Alex Dergachev
## Cookbook Name:: deploy_drupal
## Attribute:: default
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
default['deploy_drupal']['admin_pass']            = 'admin'
default['deploy_drupal']['site_name']             = 'cooked.drupal' # vhost server name
default['deploy_drupal']['sql_load_file']         = '' # absolute path to drupal SQL dump (can be .gz)
default['deploy_drupal']['sql_post_load_script']  = '' # absolute path to bash script to run after loading SQL dump

default['deploy_drupal']['apache_port']           = "80" #should be consistent with  node['apache']['listen_ports']
default['deploy_drupal']['apache_user']           = 'www-data' # user owning drupal codebase files
default['deploy_drupal']['apache_group']          = 'www-data' # group owning drupal codebase files 
default['deploy_drupal']['dev_group']             = 'drupal-dev'

default['deploy_drupal']['codebase_source_path']  =  ''  #required attribute to drupal folder containing index.php and settings.php
default['deploy_drupal']['deploy_directory']      = "/var/shared/sites/#{deploy_drupal['site_name']}/site" # can be same as codebase_source_path
default['deploy_drupal']['files_path']            = 'sites/default/files/'

default['deploy_drupal']['mysql_user']            = 'drupal_db'
default['deploy_drupal']['mysql_pass']            = 'drupal_db'
default['deploy_drupal']['db_name']               = 'drupal'

