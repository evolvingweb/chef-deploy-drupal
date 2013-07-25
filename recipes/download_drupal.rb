## Cookbook Name:: deploy-drupal
## Recipe:: download_drupal
##
## download drupal if necessary

case node['deploy-drupal']['version']
when '7' 
  version = '7.22'
when '6'
  version = '6.28'
else 
  version = node['deploy-drupal']['version']
end

project_missing = node['deploy-drupal']['get_project']['path'].empty? &&
                  node['deploy-drupal']['get_project']['git_repo'].empty?

if project_missing
  tmp_dir = "#{Chef::Config[:file_cache_path]}/#{node['deploy-drupal']['project_name']}"
  
  # temporary site directory where drupal will be extracted
  directory "#{tmp_dir}/site" do
    recursive true
  end
  repo_url = "http://ftp.drupal.org/files/projects"
  
  remote_file "#{tmp_dir}/drupal-#{version}.tar.gz" do
    source "#{repo_url}/drupal-#{version}.tar.gz"
    mode 0644
  end
  
  execute "untar-drupal" do
    cwd tmp_dir
    command "tar -xzf drupal-#{version}.tar.gz -C site --strip-components=1"
  end
  node.set['deploy-drupal']['get_project']['path'] = tmp_dir
end
