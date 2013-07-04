## Cookbook Name:: deploy-drupal
## Recipe:: fresh
## downloads Drupal 7 from drupal.org


# assemble all necessary query strings and paths
DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{node['deploy-drupal']['site_name']}"

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" + node['deploy-drupal']['site_path']

bash "download-drupal" do
  cwd DEPLOY_PROJECT_DIR
  code <<-EOH
    drush dl drupal-7 --destination=. --drupal-project-rename=#{node['deploy-drupal']['site_path']} -y
  EOH
  creates "#{DEPLOY_SITE_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
end
