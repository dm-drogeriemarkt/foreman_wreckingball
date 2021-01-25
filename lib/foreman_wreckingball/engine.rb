# frozen_string_literal: true

require 'dynflow'
require 'foreman-tasks'

module ForemanWreckingball
  class Engine < ::Rails::Engine
    engine_name 'foreman_wreckingball'

    WRECKINGBALL_STATUSES = [
      'ForemanWreckingball::ToolsStatus',
      'ForemanWreckingball::OperatingsystemStatus',
      'ForemanWreckingball::CpuHotAddStatus',
      'ForemanWreckingball::SpectreV2Status',
      'ForemanWreckingball::HardwareVersionStatus'
    ].freeze

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

    initializer 'foreman_wreckingball.load_default_settings', before: :load_config_initializers do
      table_exists = begin
                       Setting.table_exists?
                     rescue StandardError
                       false
                     end
      require_dependency File.expand_path('../../app/models/setting/wreckingball.rb', __dir__) if table_exists
    end

    initializer 'foreman_wreckingball.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_wreckingball do
        requires_foreman '>= 1.21'

        automatic_assets(false)
        precompile_assets(
          [
            'foreman_wreckingball/modal.js',
            'foreman_wreckingball/status_hosts_table.js',
            'foreman_wreckingball/status_managed_hosts_dashboard.js',
            'foreman_wreckingball/status_row.js',
            'foreman_wreckingball/status_hosts_table.css',
            'foreman_wreckingball/status_managed_hosts_dashboard.css'
          ]
        )

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
          'foreman_wreckingball/hosts/status_dashboard',
          'foreman_wreckingball/hosts/status_managed_hosts_dashboard',
          'foreman_wreckingball/hosts/status_hosts'
        ]

        menu :top_menu, :wreckingball_status_dashboard, :url_hash => { :controller => :'foreman_wreckingball/hosts', :action => :status_dashboard },
                                                        :caption => N_('VMware Status'),
                                                        :parent => :hosts_menu,
                                                        :after => :hosts

        WRECKINGBALL_STATUSES.each { |status| register_custom_status(status.constantize) }

        menu :top_menu, :wreckingball_status_managed_hosts_dashboard, url_hash: { :controller => :'foreman_wreckingball/hosts', :action => :status_managed_hosts_dashboard },
                                                                      caption: N_('VMware Managed Status'),
                                                                      parent: :monitor_menu,
                                                                      after: :audits

        register_facet(ForemanWreckingball::VmwareFacet, :vmware_facet)

        register_facet(ForemanWreckingball::VmwareHypervisorFacet, :vmware_hypervisor_facet)

        add_controller_action_scope('HostsController', :index) { |base_scope| base_scope.includes(:vmware_facet) }

        # extend host show page
        extend_page('compute_resources/show') do |context|
          context.add_pagelet :main_tabs,
                              :name => N_('Hypervisors'),
                              :partial => 'compute_resources/hypervisors_tab',
                              :onlyif => proc { |cr| cr.provider_friendly_name == 'VMware' && cr.vmware_hypervisor_facets.any? }
        end

        # add custom logger
        logger :import, enabled: true
      end
    end

    initializer 'foreman_wreckingball.dynflow_world', :before => 'foreman_tasks.initialize_dynflow' do |_app|
      ::ForemanTasks.dynflow.require!
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      ::HostStatus.extend(ForemanWreckingball::HostStatusExtensions)

      ::ComputeResource.send(:include, ForemanWreckingball::ComputeResourceExtensions)
      ::Foreman::Model::Vmware.send(:include, ForemanWreckingball::VmwareExtensions)
      ::Host::Managed.send(:include, ForemanWreckingball::HostExtensions)
      ::Host::Managed.send(:include, ForemanWreckingball::VmwareFacetHostExtensions)
      ::Host::Managed.send(:include, ForemanWreckingball::VmwareHypervisorFacetHostExtensions)
      ::HostsHelper.send(:include, ForemanWreckingball::HostsHelperExtensions)
      ::User.send(:include, ForemanWreckingball::UserExtensions)
      ::Usergroup.send(:include, ForemanWreckingball::UsergroupExtensions)

      if ForemanWreckingball.fog_patches_required?
        ForemanWreckingball.fog_vsphere_namespace::Host.send(:include, FogExtensions::ForemanWreckingball::Vsphere::Host)
        ForemanWreckingball.fog_vsphere_namespace::Server.send(:include, FogExtensions::ForemanWreckingball::Vsphere::Server)
        ForemanWreckingball.fog_vsphere_namespace::Real.send(:include, FogExtensions::ForemanWreckingball::Vsphere::Real)
        ForemanWreckingball.fog_vsphere_namespace::Mock.send(:include, FogExtensions::ForemanWreckingball::Vsphere::Mock)
      end
    rescue StandardError => e
      Rails.logger.warn "ForemanWreckingball: skipping engine hook (#{e})\n#{e.backtrace.join("\n")}"
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
    true
  rescue LoadError
    false
  end

  def self.fog_vsphere_namespace
    require 'fog/vsphere/version'
    @fog_vsphere_namespace ||= if Gem::Version.new(Fog::Vsphere::VERSION) >= Gem::Version.new('3.0.0')
                                 Fog::Vsphere::Compute
                               else
                                 Fog::Compute::Vsphere
                               end
  end
end
