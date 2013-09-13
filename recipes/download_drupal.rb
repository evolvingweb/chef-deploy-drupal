## Cookbook Name:: deploy-drupal
## Recipe:: download_drupal
##
## download drupal if necessary

case version = node['deploy-drupal']['download_drupal']['version']
when '7' 
  version = '7.22'
when '6'
  version = '6.28'
end

project_missing = node['deploy-drupal']['get_project']['path'].empty? &&
                  node['deploy-drupal']['get_project']['git_repo'].empty?

if project_missing
  tmp_dir = Chef::Config[:file_cache_path]
  
  # temporary site directory where drupal will be extracted
  directory "#{tmp_dir}/#{node['deploy-drupal']['project_name']}/site" do
    recursive true
  end
  repo_url = "http://ftp.drupal.org/files/projects"
  
  remote_file "#{tmp_dir}/drupal-#{version}.tar.gz" do
    source "#{repo_url}/drupal-#{version}.tar.gz"
    mode 0644
    action :create_if_missing
  end
  
  execute "untar-drupal" do
    cwd tmp_dir
    command "tar -xzf drupal-#{version}.tar.gz -C #{node['deploy-drupal']['project_name']}/site --strip-components=1"
  end
  node.set['deploy-drupal']['get_project']['path'] = tmp_dir + "/" +node['deploy-drupal']['project_name']
end
