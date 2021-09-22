# frozen_string_literal: true

collection @hosts

attributes :id, :name

child owner: :owner do
  attribute :name
end

if Host::Managed.reflect_on_environment?
  child :environment do
    attribute :name
  end
end

node(:path) { |host| host_path(host) }

node(:status) do |host|
  status = host.public_send(locals[:host_association])
  {
    id: status.id,
    label: status.to_label,
    icon_class: host_global_status_icon_class(status.to_global),
    status_class: host_global_status_class(status.to_global)
  }
end

node(:remediate, if: lambda do |host|
  locals[:supports_remediate] && User.current.can?(:remediate_vmware_status_hosts, host)
end) do
  {
    label: _('Remediate'),
    title: _('Remediate Host OS'),
    path: schedule_remediate_hosts_path
  }
end
