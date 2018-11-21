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

    STATUSES_MAP ||= {
      vmware_tools_status_object: ForemanWreckingball::ToolsStatus,
      vmware_operatingsystem_status_object: ForemanWreckingball::OperatingsystemStatus,
      vmware_cpu_hot_add_status_object: ForemanWreckingball::CpuHotAddStatus,
      vmware_spectre_v2_status_object: ForemanWreckingball::SpectreV2Status,
      vmware_hardware_version_status_object: ForemanWreckingball::HardwareVersionStatus
    }.freeze

    def status_dashboard
      @newest_data = Host.authorized(:view_hosts, Host).joins(:vmware_facet).maximum('vmware_facets.updated_at')
      @data = STATUSES_MAP.map do |_key, status|
        host_association = status.host_association

        # Let the database calculate status counts, then map to HostStatus::Global values
        counter = Host.authorized(:view_hosts)
                      .joins(host_association)
                      .select('host_status.status')
                      .group('host_status.status')
                      .count
                      .each_with_object({}) { |(k, v), r| r[status.to_global(k)] = v }

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

    # ajax method
    def status_hosts
      @status = STATUSES_MAP[params.fetch(:status).to_sym]

      query = Host.authorized(:view_hosts, Host)
                  .joins(@status.host_association)
                  .includes(@status.host_association, :vmware_facet, :environment)

      all_hosts = query.where.not('host_status.status': @status.global_ok_list)
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
      flash[:success] = _('Refresh Compute Resource data task was successfully scheduled.')
      task = User.as_anonymous_admin do
        ::ForemanTasks.async_task(::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync)
      end
      redirect_to(foreman_tasks_task_path(task.id))
    end

    def schedule_remediate
      @triggering = ForemanTasks::Triggering.new(mode: :immediate)
    end

    def submit_remediate
      raise Foreman::Exception, 'VMware Status can not be remediated.' unless @status.class.respond_to?(:supports_remediate?) && @status.class.supports_remediate?
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
      when 'status_dashboard'
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
