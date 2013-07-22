## Cookbook Name:: deploy-drupal
## Recipe:: get_project
##
## load specified project (if any), and
## make sure  project skeleton exists in deployment 

directory node['deploy-drupal']['project_root'] do
  recursive true
end

execute "get-project-from-git" do
  command "git clone #{node['deploy-drupal']['get_project']['git']} #{node['deploy-drupal']['project_root']}"
  group node['deploy-drupal']['dev_goup']
  creates node['deploy-drupal']['project_root']
  not_if { node['deploy-drupal']['get_project']['git'].nil? }
  notifies :restart, "service[apache2]", :delayed
end

execute "get-project-from-path" do
  command "cp -Rf '#{node['deploy-drupal']['get_project']['path']}/.' '#{node['deploy-drupal']['project_root']}'"
  group node['deploy-drupal']['dev_goup']
  creates node['deploy-drupal']['project_root']
  not_if { node['deploy-drupal']['get_project_from']['path'].nil? }
  notifies :restart, "service[apache2]", :delayed
end

index_exists = File.exists? "#{node['deploy-drupal']['drupal_root']}/index.php"
log_message = "there is " + ( index_exists ? "an" : "no" ) + 
  "index.php file in the site directory #{node['deploy-drupal']['drupal_root']}" +
  ( index_exists ? "sounds good!" : "this might not be what you want." )

log log_message  do
  level :info
end
