#!/usr/bin/env rake
task :default => 'foodcritic'

desc "Test compliance with Foodcritic"
task :foodcritic do
  Rake::Task[:prepare_sandbox].execute
  sh "foodcritic --epic-fail any #{sandbox_path}"
  Rake::Task[:destroy_sandbox].execute
end

desc "Runs knife test"
task :knife_test do
  Rake::Task[:prepare_sandbox].execute
  sh "bundle exec knife cookbook test -a -c test/knife.rb  -o #{sandbox_path}/"
  Rake::Task[:destroy_sandbox].execute
end

desc "Deploys Drupal server and runs minitest"
task :deploy_minitest do
  Rake::Task[:prepare_sandbox].execute
  Dir.chdir(sandbox_path) do
    sh "berks install -p cookbooks"
    sh "rvmsudo chef-solo -c test/solo.rb -j test/dna.json || true"
    sh "sudo cat /tmp/vagrant-chef-1/chef-stacktrace.out"
    sh "sudo cat /var/log/syslog"
  end
end

task :prepare_sandbox do
  rm_rf sandbox_path
  mkdir_p sandbox_path
  cp_r "./.", sandbox_path
end

task :destroy_sandbox do
  rm_rf sandbox_path
end

private
def sandbox_path
   "/tmp/chef-deploy-drupal"
end
