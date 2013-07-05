## Cookbook Name:: deploy-drupal
## Recipe:: default
##

include_recipe 'deploy-drupal::dependencies'
include_recipe 'deploy-drupal::load_project'
include_recipe 'deploy-drupal::download_drupal'
include_recipe 'deploy-drupal::prepare'
include_recipe 'deploy-drupal::install' 
