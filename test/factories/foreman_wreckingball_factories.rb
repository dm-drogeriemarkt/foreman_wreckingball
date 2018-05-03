# frozen_string_literal: true

FactoryBot.define do
  factory :vmware_facet, class: 'ForemanWreckingball::VmwareFacet' do
    vmware_cluster
    tools_state 2 #:toolsOk
    cpus 2
    corespersocket 1
    memory_mb 8192
    guest_id 'rhel6_64Guest'
    cpu_hot_add false
    host
  end

  factory :vmware_hypervisor_facet, class: 'ForemanWreckingball::VmwareHypervisorFacet' do
    host
    vmware_cluster
    cpu_cores 18
    cpu_sockets 1
    cpu_threads 36
    memory 412_046_372_864
    uuid { SecureRandom.uuid }
  end

  factory :vmware_cluster, class: 'ForemanWreckingball::VmwareCluster' do
    sequence(:name) { |n| "Cluster #{n}" }
    association :compute_resource, factory: [:compute_resource, :vmware]
  end

  factory :vmware_tools_status, class: 'ForemanWreckingball::ToolsStatus' do
    association :host, factory: [:host, :with_vmware_facet]
    reported_at { Time.now.utc }
    after(:build) { |status| status.status = status.to_status }
  end

  factory :vmware_operatingsystem_status, class: 'ForemanWreckingball::OperatingsystemStatus' do
    association :host, factory: [:host, :with_vmware_facet]
    reported_at { Time.now.utc }
    after(:build) { |status| status.status = status.to_status }
  end

  factory :vmware_cpu_hot_add_status, class: 'ForemanWreckingball::CpuHotAddStatus' do
    association :host, factory: [:host, :with_vmware_facet]
    reported_at { Time.now.utc }
    after(:build) { |status| status.status = status.to_status }
  end
end
