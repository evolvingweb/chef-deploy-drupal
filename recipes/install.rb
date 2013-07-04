## Cookbook Name:: deploy-drupal
## Recipe:: install
##
## installs the acquired drupal site using the configured database
##  1. load db from dump
##  2. drush si
##  3. run post-install script
##  4. install and run permission script
##  5. drush cc


# assemble all necessary query strings and paths

DRUSH_DB_URL        = "mysql://" +
                          node['deploy-drupal']['mysql_user'] + ":'" +
                          node['deploy-drupal']['mysql_pass'] + "'@localhost/" +
                          node['deploy-drupal']['db_name']

DRUSH_STATUS_CMD    = "drush status --fields=db-status \
                      | grep Connected | wc -l | xargs test 0 -eq"

DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{node['deploy-drupal']['site_name']}"

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" + node['deploy-drupal']['site_path']
DEPLOY_FILES_DIR    = DEPLOY_SITE_DIR + "/" +
                      node['deploy-drupal']['site_files_path']

DEPLOY_SCRIPT_FILE  = DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['post_script_file']

# load the drupal database from specified local SQL file
execute "load-drupal-db-from-sql" do
  cwd DEPLOY_SITE_DIR
  #TODO: not robust to errors connecting to DB
  mysql_empty_check_cmd = "drush sql-query 'show tables;' | wc -l | xargs test 0 -eq"
  only_if  "test -f '#{node['deploy-drupal']['sql_load_file']}' && #{mysql_empty_check_cmd}", :cwd => DEPLOY_PROJECT_DIR
  # Using zless instead of cat/zcat to optionally support gzipped files 
  # "`drush sql-connect`" because "drush sqlc" returns 0 even on connection failure
  command "zless '#{node['deploy-drupal']['sql_load_file']}' | `drush sql-connect`"
  notifies :run, "execute[drush cache-clear]"
end


# install Drupal Site
execute "drush-site-install" do
  cwd DEPLOY_SITE_DIR 
  # fixes sendmail error https://drupal.org/node/1826652#comment-6706102
  command "php -d sendmail_path=/bin/true /usr/share/php/drush/drush.php \
                site-install standard -y \
                --account-name=#{node['deploy-drupal']['admin_user']} \
                --account-pass=#{node['deploy-drupal']['admin_pass']} \
                --db-url=#{DRUSH_DB_URL}\
                --site-name='#{node['deploy-drupal']['site_name']}'"
 
  # requires drush 6
  only_if DRUSH_STATUS_CMD, :cwd => DEPLOY_SITE_DIR
  notifies :run, "execute[drush-suppress-http-status-error]"
end

# run customized sql-post-load-script
execute "customized-sql-post-load-script" do
  cwd DEPLOY_SITE_DIR 
  command "bash '#{DEPLOY_SCRIPT_FILE}'"
  only_if "test -f '#{DEPLOY_SCRIPT_FILE}'", :cwd => DEPLOY_PROJECT_DIR
  action :nothing
  subscribes :run, "execute[load-drupal-db-from-sql]"
end

# install the permissions script
template "/usr/local/bin/drupal-perm.sh" do
  source "drupal-perm.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :files_path => DEPLOY_FILES_DIR, 
    :user  => node['deploy-drupal']['apache_user'],
    :group => node['deploy-drupal']['dev_group_name'] 
  })
end

# fix permissions of project root
execute "fix-drupal-permissions" do
  cwd DEPLOY_PROJECT_DIR
  command "bash drupal-perm.sh"
end

# only when Drupal is served through a forwarded port
execute "drush-suppress-http-status-error" do
  cwd DEPLOY_SITE_DIR
  command "drush vset -y drupal_http_request_fails FALSE"
  action :nothing
end

# drush cache clear
execute "drush cache-clear" do
  cwd DEPLOY_SITE_DIR
  action :nothing
end
