## Cookbook Name:: deploy-drupal
## Recipe:: default
##

# include dependencies and install packages
include_recipe 'deploy-drupal::base'

# obliterate existing project if rest='true'
include_recipe 'deploy-drupal::reset' if node['deploy-drupal']['reset']=='true'

# prepare the machine for drupal installation:
# create project directory, configure apache vhost, and mysql user
include_recipe 'deploy-drupal::prepare'

# acquire code base
include_recipe 'deploy-drupal::fresh' unless node['deploy-drupal']['copy']=='true'
include_recipe 'deploy-drupal::copy' if node['deploy-drupal']['copy']=='true'

# drush site-install, fix permissions, clear cache, and done!
include_recipe 'deploy-drupal::install' 
