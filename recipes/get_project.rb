## Cookbook Name:: deploy-drupal
## Recipe:: get_project
##
## load specified project (if any), and make sure
## project skeleton exists in deployment 

# assemble all necessary absolute paths
DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_dir']+ "/" +
                      node['deploy-drupal']['project_name']

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['drupal_root_dir']
                        
directory node['deploy-drupal']['deploy_dir'] do
  recursive true
end

# only runs if project root directory does not exist
execute "get-project-from-git" do
  group node['deploy-drupal']['dev_group_name']
  cwd node['deploy-drupal']['deploy_dir']
  command "git clone " +
          node['deploy-drupal']['get_project_from']['git'] + " " +
          node['deploy-drupal']['project_name']
  creates DEPLOY_PROJECT_DIR
  not_if { node['deploy-drupal']['get_project_from']['git'].empty? }
  notifies :restart, "service[apache2]", :delayed
end

# only runs if project root directory (deploy_dir/project_name) does not exist
# TODO must raise exception if path is not a directory
execute "get-project-from-path" do
  group node['deploy-drupal']['dev_group_name']
  command "cp -Rf '#{node['deploy-drupal']['get_project_from']['path']}/.' '#{DEPLOY_PROJECT_DIR}'"
  creates DEPLOY_PROJECT_DIR
  not_if {node['deploy-drupal']['get_project_from']['path'].empty? }
  notifies :restart, "service[apache2]", :delayed
end

directory DEPLOY_SITE_DIR do
  owner node['apache']['user']
  group node['deploy-drupal']['dev_group_name']
  recursive true
end
