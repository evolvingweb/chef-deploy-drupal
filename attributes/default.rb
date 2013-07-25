## Cookbook Name:: deploy-drupal
## Attribute:: default
include_attribute 'deploy-drupal::get_project'
include_attribute 'deploy-drupal::install'

default['deploy-drupal']['version'] = '7'

# must be consistent with node['apache']['listen_ports']
default['deploy-drupal']['apache_port'] = '80' 
# user group owning drupal codebase files
default['deploy-drupal']['dev_group'] = 'root'

# vhost server name and project directory name
default['deploy-drupal']['project_name'] = 'cooked.drupal' 

# absolute path to project directory
default['deploy-drupal']['project_root'] = "/var/shared/sites/#{node['deploy-drupal']['project_name']}"

# absolute path to Drupal site, may be identical to project_root
if ( node['deploy-drupal']['get_project']['git_repo'].empty? && 
     node['deploy-drupal']['get_project']['path'].empty? )
  default['deploy-drupal']['drupal_root'] = "#{node['deploy-drupal']['project_root']}/site"
else
  default['deploy-drupal']['drupal_root'] = node['deploy-drupal']['project_root'] + "/"
                                            node['deploy-drupal']['get_project']['site_dir']
end
# absolute path to Drupal 'files' directory
default['deploy-drupal']['files_dir'] = node['deploy-drupal']['drupal_root'] + "/sites/default/files"
