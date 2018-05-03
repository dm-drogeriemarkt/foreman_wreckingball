# frozen_string_literal: true

FactoryBot.modify do
  factory :host do
    trait :with_vmware_facet do
      vmware_facet
    end

    trait :with_vmware_hypervisor_facet do
      vmware_hypervisor_facet
    end

    trait :with_vmware_tools_status do
      with_vmware_facet
      after(:create) do |host, _evaluator|
        create :vmware_tools_status, host: host
      end
    end

    trait :with_vmware_operatingsystem_status do
      with_vmware_facet
      after(:create) do |host, _evaluator|
        create :vmware_operatingsystem_status, host: host
      end
    end

    trait :with_vmware_cpu_hot_add_status do
      with_vmware_facet
      after(:create) do |host, _evaluator|
        create :vmware_cpu_hot_add_status, host: host
      end
    end

    trait :with_wreckingball_statuses do
      with_vmware_tools_status
      with_vmware_operatingsystem_status
      with_vmware_cpu_hot_add_status
    end
  end
end
