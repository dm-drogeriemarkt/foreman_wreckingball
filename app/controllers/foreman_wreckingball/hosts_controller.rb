module ForemanWreckingball
  class HostsController < ::HostsController
    before_action :find_resource, :only => [:remediate]
    before_action :find_status, :only => [:remediate]

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
      task = ::ForemanTasks.async_task(::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync)
      redirect_to(foreman_tasks_task_path(task.id))
    end

    def remediate
      raise Foreman::Exception, 'VMware Status can not be remediated.' unless @status.class.respond_to?(:supports_remediate?) && @status.class.supports_remediate?
      flash[:success] = _('Remediate VM task for %s was successfully scheduled.') % @host
      task = ::ForemanTasks.async_task(::Actions::ForemanWreckingball::Host::RemediateVmwareOperatingsystem, @host)
      redirect_to(foreman_tasks_task_path(task.id))
    end

    private

    def find_status
      @status = HostStatus::Status.find_by!(:id => params[:status_id], :host_id => @host.id)
    end

    def action_permission
      case params[:action]
      when 'status_dashboard'
        'view'
      when 'refresh_status_dashboard'
        'refresh_vmware_status'
      when 'remediate'
        'remediate_vmware_status'
      else
        super
      end
    end
  end
end
