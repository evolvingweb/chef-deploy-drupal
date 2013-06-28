## Cookbook Name:: deploy-drupal
## Attribute:: default

default['deploy-drupal']['admin_pass']            = 'admin'

# vhost server name
default['deploy-drupal']['site_name']             = 'cooked.drupal' 

# absolute path to drupal SQL dump (can be .gz)
default['deploy-drupal']['sql_load_file']         = '' 

# absolute path to bash script to run after loading SQL dump
default['deploy-drupal']['sql_post_load_script']  = '' 

#should be consistent with  node['apache']['listen_ports']
default['deploy-drupal']['apache_port']           = "80" 

# user owning drupal codebase files
default['deploy-drupal']['apache_user']           = 'www-data' 

default['deploy-drupal']['apache_group']          = 'www-data' 

# group owning drupal codebase files
default['deploy-drupal']['dev_group']             = 'sudo'

#required attribute to drupal folder containing index.php and settings.php
default['deploy-drupal']['codebase_source_path']  = ''  

# can be same as codebase_source_path
default['deploy-drupal']['deploy_directory']      = "/var/shared/sites/#{node['deploy-drupal']['site_name']}/site" 

# path to Drupal files directory, relative to site root
default['deploy-drupal']['files_path']            = 'sites/default/files/'

# MySQL username and password used by Drupal
default['deploy-drupal']['mysql_user']            = 'drupal_db'
default['deploy-drupal']['mysql_pass']            = 'drupal_db'

# MySQL database used by Drupal
default['deploy-drupal']['db_name']               = 'drupal'
