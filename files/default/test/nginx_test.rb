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
      next unless ext.index(/[\\\(\)\*\+\?]/).nil?
      
      Chef::Log.info "curling http://localhost:#{node['deploy-drupal']['nginx']['port']}/blah.#{ext}"
      
      txt = "expected Nginx to block a request to"
      command = "curl --write-out %{http_code} --silent --remote-name\
                 http://localhost:#{node['deploy-drupal']['nginx']['port']}/blah.#{ext}\
                 | grep 403"
      assert_sh command, txt
    end
  end
  def test_blocked_locations
    node['deploy-drupal']['nginx']['location_block_list'].each do |loc|
      next unless loc.index(/[\\\(\)\*\+\?]/).nil?
      
      Chef::Log.info "curling http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{loc}"
      
      txt = "expected Nginx to block a request to"
      command = "curl --write-out %{http_code} --silent --remote-name\
                 http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{loc}\
                 | grep 403"
      assert_sh command, txt
    end
  end
  def test_keyword_blocks
    node['deploy-drupal']['nginx']['keyword_block_list'].each do |key|
      next unless key.index(/[\\\(\)\*\+\?]/).nil?
      
      Chef::Log.info "http://localhost:#{node['deploy-drupal']['nginx']['port']}/foo#{key}bar"
      
      txt = "expected Nginx to block a request to"
      command = "curl --write-out %{http_code} --silent --remote-name\
                 http://localhost:#{node['deploy-drupal']['nginx']['port']}/foo#{key}bar\
                 | grep 403"
      assert_sh command, txt
    end
  end 
  def test_static_content
    minitest_log_dir = "/tmp/minitest/nginx"
    apache_access_log = node['apache']['log_dir'] + "/" +
                        node['deploy-drupal']['project_name'] + "-access.log"
    system "rm -rf #{minitest_log_dir} ; mkdir -p #{minitest_log_dir}"

    node['deploy-drupal']['nginx']['static_content'].each do |ext|
      next unless ext.index(/[\\\(\)\*\+\?]/).nil?
 
      test_file = Time.new.usec.to_s + "." + ext
      minitest_log_file = minitest_log_dir + "/" + test_file + ".minitest" 
      
      txt = "expected Nginx to not proxy pass a request to\
             http://localhost:#{node['deploy-drupal']['nginx']['port']}/#{test_file}"
      url = "localhost:#{node['deploy-drupal']['nginx']['port']}/#{test_file}"
      Chef::Log.info "curling #{url}..."
      # tail apache access log in the background and curl nginx
      # test will fail if any access to apache is recorded
      system "touch #{minitest_log_file} ; \
              touch #{node['deploy-drupal']['drupal_root']}/#{test_file} ; \
              ( tail -n0 -F #{apache_access_log} \
                | grep #{test_file} \
                | while read X; do echo $X >> #{minitest_log_file}; done\
              ) & \
              curl -G #{url} > /dev/null 2>&1 ;\
              sleep 1; kill $( ps | grep tail | awk '{print $1;}' ) > /dev/null 2>&1 \
              rm -f #{node['deploy-drupal']['drupal_root']}/#{test_file}"
      assert_sh "cat #{minitest_log_file} | wc -l | xargs test 0 -eq", txt
    end
    system "rm -rf #{minitest_log_dir}"
  end
end
