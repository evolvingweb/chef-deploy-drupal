## Cookbook Name:: deploy-drupal
## Attribute:: default

default['deploy-drupal']['admin_pass']            = 'admin'
default['deploy-drupal']['admin_user']            = 'admin'
# apache vhost port should be consistent with 
# node['apache']['listen_ports']
default['deploy-drupal']['apache_port']           = '80' 
# user owning drupal codebase files
default['deploy-drupal']['apache_user']           = 'www-data' 
# MySQL credentials
default['deploy-drupal']['mysql_user']            = 'drupal_db'
default['deploy-drupal']['mysql_pass']            = 'drupal_db'
default['deploy-drupal']['db_name']               = 'drupal'
# group owning drupal codebase files
default['deploy-drupal']['dev_group_name']        = 'root'


default['deploy-drupal']['get_project_from']['git']   = ''
default['deploy-drupal']['get_project_from']['path']  = ''

# vhost server name and deployed project directory
# if loading project from git, must be consistent repo name
default['deploy-drupal']['project_name']          = 'cooked.drupal' 

# root of the Drupal site, relative to project root
# must be directory name (no path)
default['deploy-drupal']['drupal_root_dir']       = 'site'

# path to Drupal 'files' directory, relative to site root
default['deploy-drupal']['drupal_files_dir']      = 'sites/default/files'

# absolute path to deployment directory 
# project root will be deploy_dir/project_name
default['deploy-drupal']['deploy_dir']            = '/var/shared/sites'

# Drupal version to download if there no site is provided
# if set to 'drupal' will download the latest drupal
# if set to 'false' will not download even if site is missing
default['deploy-drupal']['drupal_dl_version']     = 'drupal-7'

# path to drupal SQL dump (can be .gz), relative to copy_project_from 
default['deploy-drupal']['sql_load_file']         = ''

# absolute path to bash script to run after site install
default['deploy-drupal']['post_install_script']   = ''
