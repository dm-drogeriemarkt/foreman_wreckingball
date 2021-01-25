# frozen_string_literal: true

module ForemanWreckingball
  class HostsController < ::HostsController
    include ::ForemanTasks::Concerns::Parameters::Triggering
    include ::HostsHelper
    include ::AuthorizeHelper

    AJAX_REQUESTS = [:status_hosts].freeze
    before_action :ajax_request, :only => AJAX_REQUESTS
    before_action :find_statuses, :only => [:schedule_remediate, :submit_remediate]

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
      vmware_compute_resources = Foreman::Model::Vmware.unscoped.all

      @errors = {}

      # NOTE The call to ComputeResource#vms may slow things down
      vms_by_compute_resource_id = vmware_compute_resources.each_with_object({}) do |cr, memo|
        memo[cr.id] = cr.vms.all
      rescue StandardError => e
        @errors[cr.name] = e.message
        Foreman::Logging.exception("Failed to load VMs from compute resource #{cr.name}", e)
      end

      # Get all VM UUIDs found in any of the compute resources
      all_vm_uuids = vms_by_compute_resource_id.values.flatten.group_by(&:id).keys

      # Map all VM UUIDs to all compute resources that have access to this VM
      @vm_compute_resource_mapping = all_vm_uuids.each_with_object({}) do |uuid, obj|
        cr_ids = vms_by_compute_resource_id.select { |_cr_id, vms| vms.find { |vm| vm.id == uuid } }.keys
        obj[uuid] = vmware_compute_resources.select { |cr| cr_ids.include?(cr.id) }
      end

      @missing_hosts = []
      @wrong_hosts = []
      @more_than_one_hosts = []

      Host::Managed.authorized(:view_hosts, Host)
                   .includes(:compute_resource)
                   .where(compute_resource: vmware_compute_resources)
                   .try { |query| params[:owned_only] ? query.owned_by_current_user_or_group_with_current_user : query }
                   .each do |host|

        compute_resources = @vm_compute_resource_mapping[host.uuid]

        if compute_resources.empty?
          # VM is not found on any compute resource, vSphere does not have the vm uuid
          @missing_hosts << host
        elsif compute_resources.count > 1
          # The vm uuid is found on more than one compute resource
          @more_than_one_hosts << host
        elsif host.compute_resource_id != compute_resources.first.id
          # The host is associated to a wrong compute resource
          @wrong_hosts << host
        end
      end

      @compute_resource_authorizer = Authorizer.new(User.current, collection: vmware_compute_resources)
      @host_authorizer = Authorizer.new(User.current)
    end

    # ajax method
    def status_hosts
      @status = HostStatus.find_wreckingball_status_by_host_association(params.fetch(:status))

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
      return not_found unless @statuses.any?

      triggering = ::ForemanTasks::Triggering.new_from_params(triggering_params)
      if triggering.future?
        triggering.parse_start_at!
        triggering.parse_start_before!
      else
        triggering.start_at ||= Time.zone.now
      end

      task = User.as_anonymous_admin do
        triggering.trigger(::Actions::ForemanWreckingball::BulkRemediate, @statuses)
      end

      redirect_to foreman_tasks_task_path(task.id)
    end

    private

    def triggering_params
      %i[triggering foreman_tasks_triggering].inject({}) do |result, param_name|
        result.merge(self.class.triggering_params_filter.filter_params(params, parameter_filter_context, param_name))
      end
    end

    def statuses_params
      @statuses_params ||= params.permit(:host_association, :owned_only, status_ids: [])
    end

    def find_statuses
      @statuses = begin
        host_association = statuses_params[:host_association]
        status_class = HostStatus.find_wreckingball_status_by_host_association(host_association)
        if status_class
          Host.authorized(:remediate_vmware_status_hosts, Host)
              .joins(status_class.host_association)
              .includes(status_class.host_association)
              .try { |query| statuses_params[:owned_only] ? query.owned_by_current_user_or_group_with_current_user : query }
              .where.not('host_status.status': status_class.global_ok_list)
              .map { |host| host.send(status_class.host_association) }
        else
          HostStatus::Status.includes(:host).where(id: statuses_params[:status_ids]).select do |status|
            User.current.can?(:remediate_vmware_status_hosts, status.host)
          end
        end
      end
    end

    def action_permission
      case params[:action]
      when 'status_dashboard', 'status_hosts', 'status_managed_hosts_dashboard'
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
