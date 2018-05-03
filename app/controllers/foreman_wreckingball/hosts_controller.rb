# frozen_string_literal: true

module ForemanWreckingball
  class HostsController < ::HostsController
    include ::ForemanTasks::Concerns::Parameters::Triggering
    before_action :find_resource, :only => [:submit_remediate, :schedule_remediate]
    before_action :find_status, :only => [:submit_remediate, :schedule_remediate]

    def status_dashboard
      statuses = [
        ToolsStatus,
        OperatingsystemStatus,
        CpuHotAddStatus
      ]

      @newest_data = Host.authorized(:view_hosts, Host).joins(:vmware_facet).maximum('vmware_facets.updated_at')

      @data = statuses.map do |status|
        host_association = status.host_association
        hosts = Host.authorized(:view_hosts, Host)
                    .joins(host_association)
                    .includes(host_association)
                    .joins(:vmware_facet)
                    .includes(host_association => :host)
                    .includes(:environment)
                    .preload(:owner)
                    .order(:name)
        {
          name: status.status_name,
          hosts: hosts,
          description: status.description,
          host_association: host_association,
          supports_remediate: status.supports_remediate?
        }
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
