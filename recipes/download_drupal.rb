## Cookbook Name:: deploy-drupal
## Recipe:: download_drupal
##
## download drupal if necessary

# assemble all necessary query strings and paths

DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_dir']   + "/" +
                      node['deploy-drupal']['project_name']

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['drupal_root_dir']

DRUSH_DL            = "drush dl #{node['deploy-drupal']['drupal_dl_version']} " +
                      "--destination=#{DEPLOY_PROJECT_DIR} " +
                      "--drupal-project-rename=#{node['deploy-drupal']['drupal_root_dir']}" 

execute "download-drupal" do
  Chef::Log.info DRUSH_DL
  command DRUSH_DL
  creates DEPLOY_SITE_DIR + "/index.php"
  not_if { node['deploy-drupal']['drupal_dl_version'] == 'false' }
  notifies :restart, "service[apache2]", :delayed
end
