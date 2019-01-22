# frozen_string_literal: true

module ForemanWreckingball
  class HostsController < ::HostsController
    include ::ForemanTasks::Concerns::Parameters::Triggering
    include ::HostsHelper
    if Gem::Version.new(SETTINGS[:version].short) < Gem::Version.new('1.20')
      include ::ApplicationHelper
    else
      include ::AuthorizeHelper
    end

    AJAX_REQUESTS = [:status_hosts].freeze
    before_action :ajax_request, :only => AJAX_REQUESTS
    before_action :find_resource, :only => [:submit_remediate, :schedule_remediate]
    before_action :find_status, :only => [:submit_remediate, :schedule_remediate]

    def status_dashboard
      @newest_data = Host.authorized(:view_hosts).joins(:vmware_facet).maximum('vmware_facets.updated_at')
      host_ids = Host.authorized(:view_hosts)
                     .try { |query| params[:owned_only] ? query.owned_by_current_user_or_group_with_current_user : query }
                     .pluck(:id)

      @data = HostStatus.wreckingball_statuses.map do |status|
        counter = status.where(host_id: host_ids)
                        .select(:status)
                        .group(:status)
                        .count
                        .transform_keys { |key| status.to_global(key) }

        {
          name: status.status_name,
          description: status.description,
          host_association: status.host_association,
          supports_remediate: status.supports_remediate?,
          counter: {
            ok: counter[HostStatus::Global::OK] || 0,
            warning: counter[HostStatus::Global::WARN] || 0,
            critical: counter[HostStatus::Global::ERROR] || 0
          }
        }
      end
    end

    def status_managed_hosts_dashboard
      @hosts = Host::Managed.authorized(:view_hosts, Host)
                            .try { |query| params[:owned_only] ? query.owned_by_current_user_or_group_with_current_user : query }

      compute_resources = ComputeResource.where(:type => 'Foreman::Model::Vmware')

      # get all vms by compute resource id
      vms_by_compute_resource_id = {}
      # NOTE The call to ComputeResource#vms may slow things down
      compute_resources.each { |cr| vms_by_compute_resource_id[cr.id] = cr.vms(eager_loading: true) }

      vms_by_uuid = vms_by_compute_resource_id.values.flatten.group_by(&:uuid)

      # Find all hosts with duplicate VMs
      @duplicate_vms = vms_by_uuid.select { |_uuid, vms| vms.size > 1 }

      @missing_hosts = []
      @different_hosts = []

      @hosts.each do |host|
        next unless host.compute_resource_id

        # find the compute resource id of the host in the vm map
        cr_id, _vms = vms_by_compute_resource_id.find { |_cr_id, vms| vms.find { |vm| vm.uuid == host.uuid } }

        if cr_id.nil?
          # No compute resource id is found, vSphere does not have the vm uuid
          @missing_hosts << host
        elsif cr_id != host.compute_resource_id
          # The host uuid is found in a different compute resource
          @different_hosts << host
        end
      end
    end

    # ajax method
    def status_hosts
      @status = HostStatus.find_wreckingball_status_by_host_association(params.fetch(:status).to_sym)

      all_hosts = Host.authorized(:view_hosts, Host)
                      .joins(@status.host_association)
                      .try { |query| params[:owned_only] ? query.owned_by_current_user_or_group_with_current_user : query }
                      .includes(@status.host_association, :vmware_facet, :environment)
                      .where.not('host_status.status': @status.global_ok_list)
                      .preload(:owner)
                      .order(:name)

      @count = all_hosts.size
      @hosts = all_hosts.paginate(page: params.fetch(:page, 1), per_page: params.fetch(:per_page, 100))

      respond_to do |format|
        format.json do
          Rabl::Renderer.json(@hosts, 'foreman_wreckingball/hosts/status_hosts',
                              view_path: "#{ForemanWreckingball::Engine.root}/app/views",
                              scope: self)
        end
      end
    end

    def refresh_status_dashboard
      if ForemanTasks::Task.active.where(label: ::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync.to_s).empty?
        flash[:success] = _('Refresh Compute Resource data task was successfully scheduled.')
        task = User.as_anonymous_admin do
          ::ForemanTasks.async_task(::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync)
        end
        redirect_to(foreman_tasks_task_path(task.id))
      else
        flash[:warning] = _('Refresh Compute Resource data task is already running. Please wait for the running task to finish.')
        redirect_to status_dashboard_hosts_path
      end
    end

    def schedule_remediate
      @triggering = ForemanTasks::Triggering.new(mode: :immediate)
    end

    def submit_remediate
      raise Foreman::Exception, _('VMware Status can not be remediated.') unless @status.class.respond_to?(:supports_remediate?) && @status.class.supports_remediate?
      task = User.as_anonymous_admin do
        triggering = ::ForemanTasks::Triggering.new_from_params(triggering_params)
        if triggering.future?
          triggering.parse_start_at!
          triggering.parse_start_before!
        else
          triggering.start_at ||= Time.zone.now
        end

        triggering.trigger(@status.class.remediate_action, @host)
      end
      flash[:success] = _('Remediate VM task for %s was successfully scheduled.') % @host
      redirect_to(foreman_tasks_task_path(task.id))
    end

    private

    def triggering_params
      %i[triggering foreman_tasks_triggering].inject({}) do |result, param_name|
        result.merge(self.class.triggering_params_filter.filter_params(params, parameter_filter_context, param_name))
      end
    end

    def find_status
      @status = HostStatus::Status.find_by!(:id => params[:status_id], :host_id => @host.id)
    end

    def action_permission
      case params[:action]
      when 'status_dashboard', 'status_hosts'
        'view'
      when 'refresh_status_dashboard'
        'refresh_vmware_status'
      when 'schedule_remediate', 'submit_remediate'
        'remediate_vmware_status'
      else
        super
      end
    end
  end
end
