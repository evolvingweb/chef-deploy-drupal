#
## Author:: Alex Dergachev
## Cookbook Name:: deploy_drupal
## Recipe:: pear_dependencies
##
## Copyright 2012, Evolving Web Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

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
