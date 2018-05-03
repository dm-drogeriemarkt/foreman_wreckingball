# frozen_string_literal: true

require 'dynflow'
require 'foreman-tasks'

module ForemanWreckingball
  class Engine < ::Rails::Engine
    engine_name 'foreman_wreckingball'

    config.autoload_paths += Dir["#{config.root}/app/lib"]
    config.autoload_paths += Dir["#{config.root}/app/services"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]

    initializer 'foreman_wreckingball.register_paths' do |_app|
      ::ForemanTasks.dynflow.config.eager_load_paths.concat(%W[#{ForemanWreckingball::Engine.root}/app/lib/actions])
    end

    # Add any db migrations
    initializer 'foreman_wreckingball.load_app_instance_data' do |app|
      ForemanWreckingball::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_wreckingball.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_wreckingball do
        requires_foreman '>= 1.17'

        security_block :foreman_wreckingball do
          permission :refresh_vmware_status_hosts, {
            :'foreman_wreckingball/hosts' => [:refresh_status_dashboard]
          }, :resource_type => 'Host'
          permission :remediate_vmware_status_hosts, {
            :'foreman_wreckingball/hosts' => [:schedule_remediate, :submit_remediate]
          }, :resource_type => 'Host'
        end

        # Extend built in permissions
        Foreman::AccessControl.permission(:view_hosts).actions.concat [
          'foreman_wreckingball/hosts/status_dashboard'
        ]

        menu :top_menu, :wreckingball_status_dashboard, :url_hash => { :controller => :'foreman_wreckingball/hosts', :action => :status_dashboard },
                                                        :caption => N_('VMware Status'),
                                                        :parent => :hosts_menu,
                                                        :after => :hosts

        register_custom_status(ForemanWreckingball::ToolsStatus)
        register_custom_status(ForemanWreckingball::OperatingsystemStatus)
        register_custom_status(ForemanWreckingball::CpuHotAddStatus)

        register_facet(ForemanWreckingball::VmwareFacet, :vmware_facet)

        register_facet(ForemanWreckingball::VmwareHypervisorFacet, :vmware_hypervisor_facet)

        add_controller_action_scope(HostsController, :index) { |base_scope| base_scope.includes(:vmware_facet) }
      end
    end

    initializer 'foreman_wreckingball.dynflow_world', :before => 'foreman_tasks.initialize_dynflow' do |_app|
      ::ForemanTasks.dynflow.require!
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        ::ComputeResource.send(:include, ForemanWreckingball::ComputeResourceExtensions)
        ::Foreman::Model::Vmware.send(:include, ForemanWreckingball::VmwareExtensions)
        ::Host::Managed.send(:include, ForemanWreckingball::HostExtensions)
        ::Host::Managed.send(:include, ForemanWreckingball::VmwareFacetHostExtensions)
        ::Host::Managed.send(:include, ForemanWreckingball::VmwareHypervisorFacetHostExtensions)
        ::HostsHelper.send(:include, ForemanWreckingball::HostsHelperExtensions)

        if ForemanWreckingball.fog_patches_required?
          Fog::Compute::Vsphere::Host.send(:include, FogExtensions::ForemanWreckingball::Vsphere::Host)
          Fog::Compute::Vsphere::Real.send(:include, FogExtensions::ForemanWreckingball::Vsphere::Real)
        end
      rescue StandardError => e
        Rails.logger.warn "ForemanWreckingball: skipping engine hook (#{e})\n#{e.backtrace.join("\n")}"
      end

      # load 'foreman_wreckingball/scheduled_jobs.rb'
    end

    initializer 'foreman_wreckingball.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_wreckingball'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end

  def self.fog_patches_required?
    return unless Foreman::Model::Vmware.available?
    require 'fog/vsphere'
    require 'fog/vsphere/compute'
    require 'fog/vsphere/models/compute/host'
    !::Fog::Compute::Vsphere::Host.instance_methods.include?(:uuid)
  rescue LoadError
    false
  end
end
