## Cookbook Name:: deploy-drupal
## Attribute:: default

default['deploy-drupal']['admin_pass']            = 'admin'

# vhost server name
default['deploy-drupal']['site_name']             = 'cooked.drupal' 

# apache vhost port should be consistent with 
# node['apache']['listen_ports']
default['deploy-drupal']['apache_port']           = "80" 

# user owning drupal codebase files
default['deploy-drupal']['apache_user']           = 'www-data' 

default['deploy-drupal']['apache_group']          = 'www-data' 

# group owning drupal codebase files
default['deploy-drupal']['dev_group']             = 'sudo'

# path to the root of an existing project to be 
# loaded, the contents of this path will be 
# copied to deploy_project_base/site_name/
default['deploy-drupal']['source_project_path']   = ''

# root of the Drupal site, relative to project_path
# this must be such that project_path/drupal_site_path/ contains index.php
default['deploy-drupal']['source_site_path']      = ''

# absolute path to deployment directory
# the Drupal site root would be deploy_path/site_name/site
default['deploy-drupal']['deploy_base_path']      = '/var/shared/sites'

# path to Drupal "files" directory, relative to site root
default['deploy-drupal']['site_files_path']       = 'sites/default/files'

# path to drupal SQL dump (can be .gz), relative to source_project_path
default['deploy-drupal']['sql_load_file']         = 'db/dump.sql.gz' 

# absolute path to bash script to run after loading SQL dump
default['deploy-drupal']['post_script_file']      = ''


# MySQL username and password used by Drupal
default['deploy-drupal']['mysql_user']            = 'drupal_db'
default['deploy-drupal']['mysql_pass']            = 'drupal_db'

# MySQL database used by Drupal
default['deploy-drupal']['db_name']               = 'drupal'
