# frozen_string_literal: true

require 'rake/testtask'

# Tasks
namespace :foreman_wreckingball do
  namespace :vmware do
    desc 'Synchonize VMware compute resource data'
    task sync: ['environment', 'dynflow:client'] do
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

Rake::Task[:test].enhance ['test:foreman_wreckingball']
