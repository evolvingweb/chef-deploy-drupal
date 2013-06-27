#!/usr/bin/env rake
task :default => 'foodcritic'

desc "Test compliance with Foodcritic"
task :foodcritic do
  Rake::Task[:prepare_sandbox].execute
  if Gem::Version.new("1.9.2") <= Gem::Version.new(RUBY_VERSION.dup)
    sh "foodcritic --epic-fail any #{sandbox_path}"
  else
    puts "WARN: foodcritic run is skipped as Ruby #{RUBY_VERSION} is < 1.9.2."
  end
  Rake::Task[:destroy_sandbox].execute
end

desc "Runs knife test"
task :knife_test do
  Rake::Task[:prepare_sandbox].execute
  sh "bundle exec knife cookbook test -a -c .knife.rb  -o #{sandbox_path}/"
  Rake::Task[:destroy_sandbox].execute
end

task :prepare_sandbox do
  files = %w{*.md *.rb attributes definitions files libraries providers recipes resources templates}

  rm_rf sandbox_path
  mkdir_p sandbox_path
  cp_r "site-cookbooks/.", sandbox_path
end

task :destroy_sandbox do
  rm_rf sandbox_path
end

private
def sandbox_path
    File.join(File.dirname(__FILE__), %w{tmp vagrant-chef-drupal})
end
