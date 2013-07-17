require 'minitest/spec'
# Very simple minitest recipe
# Cookbook Name:: deploy-drupal
# Spec:: default
#
describe_recipe 'deploy-drupal::default' do

  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources
  #TODO this is the path to the deployed site
  # currently this is hardcoded as an attribute
  # to minitest
  #node['deploy-drupal']['deploy_base_path']+ "/"
  #node['deploy-drupal']['site_name'] + "/" +
  #node['deploy-drupal']['site_path']
  
  describe "files" do
    it "creates the index.php file" do
      file("#{node['minitest']['drupal_site_dir']}/index.php").must_exist
    end

    it "creates the settings.php file" do
      file("#{node['minitest']['drupal_site_dir']}/sites/default/settings.php").must_exist
    end
    
    it "has the expected ownership and permissions" do
      file(node['minitest']['drupal_site_dir']).must_exist.with(:owner, node['apache']['user'])
    end

    # And you can chain attributes together if you are asserting several.
    # You don't want to get too carried away doing this but it can be useful.
    it "files folder must be appropriately set" do
      file("#{node['minitest']['drupal_site_dir']}/index.php").
        must_have(:mode, "460").
        with(:owner, node['apache']['user']).and(:group,node['deploy-drupal']['dev_group_name'])
    end
    # = Directories =
    # The file existence and permissions matchers are also valid for
    # directories:
    it "has appropriate folder permissions in drupal site" do
      directory("#{node['minitest']['drupal_site_dir']}/includes").
        must_have(:mode, "2570").
        must_exist.with(:owner, node['apache']['user']).and(:group,node['deploy-drupal']['dev_group_name'])
    end

  end

  describe "services" do
    # You can assert that a service must be running following the converge:
    it "runs as a daemon" do
      service("mysql").must_be_running
    end

    # And that it will start when the server boots:
    it "boots on startup" do
      service("apache2").must_be_enabled
    end
  end

  describe "users and groups" do
    # = Users =
    # Check if a user has been created:
    it "creates apache user" do
      user(node['apache']['user']).must_exist
    end
  end
end

# TODO This is a traditional Minitest test case, has to be somehow merged with
# chef-handler style test cases (above)
class TestDrupal < MiniTest::Chef::TestCase
  def test_that_drupal_is_served
    assert system("curl --silent localhost:80 | grep '<title>' | grep 'cooked.drupal'")
  end
end
