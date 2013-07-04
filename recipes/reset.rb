## Cookbook Name:: deploy-drupal
## Recipe:: default
##
## destroy the project root directory and removes the Drupal database user 
## if reset attribue is set to "true".
## keeps a drush archive-dump in drush's default directory (~/drush-backups/)

# assemble all necessary query strings and paths
DB_ROOT_CONNECTION  = "mysql  --user='root'\
                              --host='localhost'\
                              --password='#{node['mysql']['server_root_password']}'"

DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{node['deploy-drupal']['site_name']}"

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" + node['deploy-drupal']['site_path']



bash "reset-project" do
  code <<-EOH
    cd #{DEPLOY_SITE_DIR}
    drush archive-dump --tar-options="--exclude=.git"
    drush sql-query "DROP DATABASE #{node['deploy-drupal']['db_name']};"
    #{DB_ROOT_CONNECTION} -e "DROP DATABASE #{node['deploy-drupal']['db_name']};"
    #{DB_ROOT_CONNECTION} -e "REVOKE ALL FROM #{node['deploy-drupal']['mysql_user']};"
    #{DB_ROOT_CONNECTION} -e "DROP USER '#{node['deploy-drupal']['mysql_user']}'@'localhost';"
    rm -rf #{DEPLOY_PROJECT_DIR}/*
  EOH
  only_if { node['deploy-drupal']['reset'] == "true" }
end
