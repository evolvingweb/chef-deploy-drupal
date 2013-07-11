## Cookbook Name:: deploy-drupal
## Recipe:: nginx
##
## set up an Nginx server in front of Apache 

# assemble all necessary query strings and paths
include_recipe 'deploy-drupal::default'
include_recipe 'nginx::default'

DEPLOY_SITE_DIR     = node['deploy-drupal']['deploy_dir']   + "/" +
                      node['deploy-drupal']['project_name'] + "/" +
                      node['deploy-drupal']['drupal_root_dir']

# load the nginx site template
template "#{node['nginx']['dir']}/sites-available/#{node['deploy-drupal']['project_name']}" do
  source "nginx_site.conf.erb"
  mode 0644
  owner "root"
  group "root"
  variables({
    :site_path => DEPLOY_SITE_DIR
  })
  notifies :reload, "service[nginx]", :delayed
end

# by default is set to enabled = true and timing = delayed
nginx_site node['deploy-drupal']['project_name'] do
end
