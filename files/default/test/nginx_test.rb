require 'minitest/spec'
# minitest recipe
# Cookbook Name:: deploy-drupal
# Spec:: nginx
#
include MiniTest::Chef::Assertions
include MiniTest::Chef::Context
include MiniTest::Chef::Resources
# Custom Tests:
class TestNginx < MiniTest::Chef::TestCase
  def test_blocked_extensions
    node['deploy-drupal']['nginx']['extension_block_list'].each do |ext|
      txt = "expected Nginx to block a request to"
      next unless ext.index(/[\\\(\)\*\+\?]/).nil?
      Chef::Log.info "curling http://localhost:#{node['deploy-drupal']['nginx']['port']}/blah.#{ext}"
      command = "curl --write-out %{http_code} --silent --remote-name\
                 http://localhost:#{node['deploy-drupal']['nginx']['port']}/blah.#{ext}\
                 | grep 403"
      assert_sh command, txt
    end
  end
  def test_blocked_locations
    node['deploy-drupal']['nginx']['location_block_list'].each do |loc|
      txt = "expected Nginx to block a request to"
      next unless loc.index(/[\\\(\)\*\+\?]/).nil?
      Chef::Log.info "curling http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{loc}"
      command = "curl --write-out %{http_code} --silent --remote-name\
                 http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{loc}\
                 | grep 403"
      assert_sh command, txt
    end
  end
  def test_keyword_blocks
    node['deploy-drupal']['nginx']['keyword_block_list'].each do |key|
      txt = "expected Nginx to block a request to"
      next unless key.index(/[\\\(\)\*\+\?]/).nil?
      Chef::Log.info "http://localhost:#{node['deploy-drupal']['nginx']['port']}/foo#{key}bar"
      command = "curl --write-out %{http_code} --silent --remote-name\
                 http://localhost:#{node['deploy-drupal']['nginx']['port']}/foo#{key}bar\
                 | grep 403"
      assert_sh command, txt
    end
  end 
  def test_static_content
    node['deploy-drupal']['nginx']['static_content'].each do |ext|
      txt = "expected Nginx to not proxy pass a request to"
      next unless ext.index(/[\\\(\)\*\+\?]/).nil?
      test_file = "#{Time.new.usec}.#{ext}"
      Chef::Log.info "curling http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{test_file}"
      system("touch #{node['minitest']['drupal_site_dir']}/#{test_file}")
      command = "(sleep 0.5;  curl --silent\
                http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{test_file}) & \
                ( tail -n0 -F \
                 #{node['apache']['log_dir']}/#{node['deploy-drupal']['project_name']}-access.log \
                 pid=$! | grep -m 1 '#{test_file}' && exit 1 ) & \
                 ( sleep 1; kill $pid; )"
      Chef::Log.info command
      assert_sh command, txt
      system("rm #{node['minitest']['drupal_site_dir']}/#{test_file}")
    end
  end
end
