# frozen_string_literal: true

require 'rake/testtask'

# Tasks
namespace :foreman_wreckingball do
  namespace :vmware do
    desc 'Synchonize VMware compute resource data'
    task :sync => :environment do
      User.as_anonymous_admin do
        ::ForemanTasks.sync_task(::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync)
      end
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanWreckingball'
  Rake::TestTask.new(:foreman_wreckingball) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_wreckingball do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_wreckingball) do |task|
        task.patterns = ["#{ForemanWreckingball::Engine.root}/app/**/*.rb",
                         "#{ForemanWreckingball::Engine.root}/lib/**/*.rb",
                         "#{ForemanWreckingball::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_wreckingball'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_wreckingball']

load 'tasks/jenkins.rake'
Rake::Task['jenkins:unit'].enhance ['test:foreman_wreckingball', 'foreman_wreckingball:rubocop'] if Rake::Task.task_defined?(:'jenkins:unit')
