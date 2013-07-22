require 'minitest/spec'
# Very simple minitest recipe
# Cookbook Name:: deploy-drupal
# Spec:: default
#
include MiniTest::Chef::Assertions
include MiniTest::Chef::Context
include MiniTest::Chef::Resources

describe_recipe 'deploy-drupal::default' do
  describe "files" do
    it "creates the index.php file" do
      file("#{node['deploy-drupal']['drupal_root']}/index.php").must_exist
    end

    it "creates the settings.php file" do
      file("#{node['deploy-drupal']['drupal_root']}/sites/default/settings.php").
      must_exist
    end
    it "has the expected ownership and permissions" do
      file(node['deploy-drupal']['drupal_root']).
      must_exist.with(:owner, node['apache']['user'])
    end

    # And you can chain attributes together if you are asserting several.
    # You don't want to get too carried away doing this but it can be useful.
    it "files folder must be appropriately set" do
      file("#{node['deploy-drupal']['drupal_root']}/index.php").
        must_exist.
        must_have(:mode, "0460").
        with(:owner, node['apache']['user']).
        and(:group,node['deploy-drupal']['dev_group'])
    end
    # = Directories =
    # The file existence and permissions matchers are also valid for
    # directories:
    it "has appropriate folder permissions in drupal site" do
      directory("#{node['deploy-drupal']['drupal_root']}/includes").
        must_have(:mode, "2570").
        must_exist.with(:owner, node['apache']['user']).
        and(:group,node['deploy-drupal']['dev_group'])
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
# Custom Tests:
class TestDrupal < MiniTest::Chef::TestCase
  def test_that_drupal_is_served
    txt = "tried to access the Drupal site #{node['deploy-drupal']['project_name']}\
           at localhost:#{node['deploy-drupal']['apache_port']}"
    command = "curl --silent localhost:#{node['deploy-drupal']['apache_port']}\
              | grep '<title>' | grep '#{node['deploy-drupal']['project_name']}'"
    assert_sh command, txt
  end
end
