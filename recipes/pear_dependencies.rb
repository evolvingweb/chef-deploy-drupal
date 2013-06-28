## Cookbook Name:: deploy-drupal
## Recipe:: pear_dependencies

# build-essential needed for PECL.
include_recipe "build-essential"

pkgs = value_for_platform(
  [ "centos", "redhat", "fedora" ] => {
    "default" => %w{ pcre-devel php-mcrypt }
  },
  [ "debian", "ubuntu" ] => {
    "default" => %w{ libpcre3-dev php5-mcrypt }
  },
  "default" => %w{ libpcre3-dev php5-mcrypt }
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

# php_pear "PDO" do
#   action :install
# end

# Install APC for increased performance. rfc1867 support also provides minimal
# feedback for file uploads.  Requires pcre library.

# instead of php_pear "APC" use package for Debian
# TODO move to pkgs above
package "php-apc" do
  action :install
end
#php_pear "APC" do
#  directives(:shm_size => "70M", :rfc1867 => 1)
#  version "3.1.6" # TODO Somehow Chef PEAR/PECL provider causes debugging to be enabled on later builds.
#  action :install
#end

# Install uploadprogress for better feedback during Drupal file uploads.
php_pear "uploadprogress" do
  action :install
end
