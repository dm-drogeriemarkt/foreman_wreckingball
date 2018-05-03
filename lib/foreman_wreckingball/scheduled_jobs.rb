# frozen_string_literal: true

# First, we check if there's a job already enqueued
pending_jobs = ::Foreman::Application.dynflow.world.persistence.find_execution_plans(filters: { :state => 'scheduled' })
scheduled_job = pending_jobs.select do |job|
  delayed_plan = ::Foreman::Application.dynflow.world.persistence.load_delayed_plan(job.id)
  next if delayed_plan.blank?
  delayed_plan.to_hash[:serialized_args].first['job_class'] == 'UpdateHostsVmwareFacets'
end

# Only schedule the job if there isn't a scheduled job
UpdateHostsVmwareFacets.perform_later if scheduled_job.blank?
