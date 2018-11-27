# frozen_string_literal: true

FactoryBot.modify do
  factory :some_task do
    trait :running do
      state 'running'
    end

    trait :stopped do
      state 'stopped'
    end

    trait :vmware_sync do
      label ::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync.to_s
    end
  end
end
