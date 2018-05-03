# frozen_string_literal: true

FactoryBot.modify do
  factory :compute_resource do
    trait :with_vmware_clusters do
      transient do
        vmware_clusters_count 1
      end

      after(:create) do |compute_resource, evaluator|
        create_list(:vmware_cluster, evaluator.vmware_clusters_count, compute_resource: compute_resource)
      end
    end
  end
end
