# frozen_string_literal: true

collection @hosts

attributes :name

child owner: :owner do
  attribute :name
end

child :environment do
  attribute :name
end

node(:path) { |host| host_path(host) }

node(:status) do |host|
  status = host.public_send(locals[:host_association])
  {
    label: status.to_label,
    icon_class: host_global_status_icon_class(status.to_global),
    status_class: host_global_status_class(status.to_global)
  }
end

node(:remediate, if: lambda do |host|
  locals[:supports_remediate] && begin
    options = hash_for_schedule_remediate_host_path(id: host,
                                                    status_id: host.public_send(locals[:host_association]).id)
                                                                   .merge(auth_object: host,
                                                                          permission: :remediate_vmware_status_hosts)
    authorized_for(options)
  end
end) do |host|
  status_id = host.public_send(locals[:host_association]).id
  {
    label: _('Remediate'),
    title: _('Remediate Host OS'),
    path: schedule_remediate_host_path(host, status_id: status_id)
  }
end
