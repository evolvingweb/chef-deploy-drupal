### Cookbook Name:: deploy-drupal
# Attribute:: get_project

default['deploy-drupal']['get_project']['path']  = ''
default['deploy-drupal']['get_project']['git_repo']   = ''
default['deploy-drupal']['get_project']['git_branch'] = 'master'
# Drupal site directory relative to project path,
# will be disregarded if no path or git url is specified
default['deploy-drupal']['get_project']['site_dir'] = 'site'
