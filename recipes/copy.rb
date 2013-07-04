## Cookbook Name:: deploy-drupal
## Recipe:: copy
## copies the entire copy_project_from directory to deployment root

# assemble all necessary query strings and paths
SOURCE_SITE_DIR     = node['deploy-drupal']['copy_project_from'] + "/" +
                      node['deploy-drupal']['site_path']

DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{node['deploy-drupal']['site_name']}"

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" + node['deploy-drupal']['site_path']


bash "copy-drupal-site" do 
  # see http://superuser.com/a/367303 for cp syntax discussion
  # assumes target directory already exists
  code <<-EOH
    cp -Rf #{node['deploy-drupal']['copy_project_from']}/. '#{DEPLOY_PROJECT_DIR}'
  EOH
  # If identical, `creates "index.php"` will prevent resource execution.
  # This is great if you want to deploy directly to Vagrant shared folder
  creates "#{DEPLOY_SITE_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
  only_if(
    "test -d '#{SOURCE_SITE_DIR}' && \
     test -f '#{SOURCE_SITE_DIR}/index.php'"
  )
end
