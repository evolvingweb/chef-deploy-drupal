## Cookbook Name:: deploy-drupal
## Recipe:: default
##

include_recipe 'deploy-drupal::dependencies'
include_recipe 'deploy-drupal::apc'
include_recipe 'deploy-drupal::xhprof'
include_recipe 'deploy-drupal::download_drupal'
include_recipe 'deploy-drupal::get_project'
include_recipe 'deploy-drupal::install'
