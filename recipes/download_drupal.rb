## Cookbook Name:: deploy-drupal
## Recipe:: download_drupal
##
## download drupal if necessary

# temporary project directory where drupal will be downloaded
tmp_dir = "#{Chef::Config[:file_cache_path]}/#{node['deploy-drupal']['project_name']}"

directory "#{tmp_dir}/site" do
  recursive true
end

case node['deploy-drupal']['version']
when '7' 
  version = '7.22'
when '6'
  version = '6.28'
else 
  version = node['deploy-drupal']['version']
end

project_missing = node['deploy-drupal']['get_project']['path'].empty? &&
                  node['deploy-drupal']['get_project']['git'].empty?

repo_url = "http://ftp.drupal.org/files/projects"

execute "download-drupal" do
  cwd tmp_dir
  command "curl #{repo_url}/drupal-#{version}.tar.gz | tar xz -C site --strip-components=1"
  only_if { project_missing }
end

if project_missing
  node.set['deploy-drupal']['get_project']['path'] = tmp_dir
end
