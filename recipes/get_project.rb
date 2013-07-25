## Cookbook Name:: deploy-drupal
## Recipe:: get_project
##
## load specified project (if any), and
## make sure  project skeleton exists in deployment 

directory node['deploy-drupal']['project_root'] do
  group node['deploy-drupal']['dev_group']
  recursive true
end

project = node['deploy-drupal']['project_root']
gitclone = "git clone #{node['deploy-drupal']['get_project']['git_repo']} #{project};"
gitcheckout = "cd #{project}; git checkout #{node['deploy-drupal']['get-project']['git_branch']}"
# clone git repo and checkout branch
execute "get-project-from-git" do
  command gitclone + git checkout
  group node['deploy-drupal']['dev_goup']
  creates node['deploy-drupal']['project_root']
  not_if { node['deploy-drupal']['get_project']['git'].nil? }
  notifies :restart, "service[apache2]"
end

execute "get-project-from-path" do
  command "cp -Rf '#{node['deploy-drupal']['get_project']['path']}/.' '#{node['deploy-drupal']['project_root']}'"
  group node['deploy-drupal']['dev_goup']
  creates node['deploy-drupal']['drupal_root'] + "/index.php"
  not_if { node['deploy-drupal']['get_project']['path'].nil? }
  notifies :restart, "service[apache2]"
end

index_exists = File.exists? "#{node['deploy-drupal']['drupal_root']}/index.php"
drupal_root_msg = "there is " + ( index_exists ? "an" : "no" ) + 
  " index.php file in the site directory #{node['deploy-drupal']['drupal_root']}" +
  ( index_exists ? "sounds good!" : "this is probably not what you want." )

log drupal_root_msg do
  level index_exists ? :info : :warn
end
