require 'minitest/spec'
# Super simplistic minitest recipe
# Cookbook Name:: deploy_drupal
# Spec:: default
#
describe_recipe 'deploy_drupal::default' do

  # It's often convenient to load these includes in a separate helper along with
  # your own helper methods, but here we just include them directly:
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  describe "files" do

    # = Testing that a file exists =
    it "creates the index.php file" do
      file("/var/shared/sites/cooked.drupal/site/index.php").must_exist
    end

    it "creates the settings.php file" do
      file("/var/shared/sites/cooked.drupal/site/sites/default/settings.php").must_exist
    end
    
    it "has the expected ownership and permissions" do
      file("/var/shared/sites/cooked.drupal/site").must_exist.with(:owner, "www-data")
    end

    # And you can chain attributes together if you are asserting several.
    # You don't want to get too carried away doing this but it can be useful.
    it "files folder must be appropriately set" do
      file("/var/shared/sites/cooked.drupal/site/index.php").must_have(:mode, "460").with(:owner, "www-data").and(:group, "drupal-dev")
    end
    # = Directories =
    # The file existence and permissions matchers are also valid for
    # directories:
    it "has appropriate folder permissions in drupal site" do
      directory("/var/shared/sites/cooked.drupal/site/includes").must_have(:mode, "2570").must_exist.with(:owner, "www-data").and(:group,"drupal-dev")
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
      user("www-data").must_exist
    end
    
    # = Groups =
    it "creates the dev group" do
      group("drupal-dev").must_exist
    end

    # Check for group membership, you can pass a single user or an array of
    # users:
    it "grants group membership to the expected users" do
      group("drupal-dev").wont_include('www-data')
    end
  end
  
  describe "drupal site" do
    # check if the served page on localhost:80 is the intended drupal site
    assert_sh "curl --silent localhost:80 | grep '<title>' | grep 'cooked.drupal'"
  end
end
