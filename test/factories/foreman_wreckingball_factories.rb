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
    hardware_version 'vmx-10'
    cpu_features [
      'cpuid.SSE3',
      'cpuid.PCLMULQDQ',
      'cpuid.SSSE3',
      'cpuid.CMPXCHG16B',
      'cpuid.PCID',
      'cpuid.SSE41',
      'cpuid.SSE42',
      'cpuid.POPCNT',
      'cpuid.AES',
      'cpuid.XSAVE',
      'cpuid.AVX',
      'cpuid.DS',
      'cpuid.SS',
      'cpuid.XCR0_MASTER_SSE',
      'cpuid.XCR0_MASTER_YMM_H',
      'cpuid.LAHF64',
      'cpuid.NX',
      'cpuid.RDTSCP',
      'cpuid.LM',
      'cpuid.Intel'
    ]
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
    feature_capabilities [
      'cpuid.3DNOW',
      'cpuid.3DNOWPLUS',
      'cpuid.3DNPREFETCH',
      'cpuid.ABM',
      'cpuid.ADX',
      'cpuid.AES',
      'cpuid.AMD',
      'cpuid.AVX',
      'cpuid.AVX2',
      'cpuid.BMI1',
      'cpuid.BMI2',
      'cpuid.CMPXCHG16B',
      'cpuid.CR8AVAIL',
      'cpuid.Cyrix',
      'cpuid.DS',
      'cpuid.ENFSTRG',
      'cpuid.EXTAPICSPC',
      'cpuid.F16C',
      'cpuid.FFXSR',
      'cpuid.FMA',
      'cpuid.FMA4',
      'cpuid.FSGSBASE',
      'cpuid.HLE',
      'cpuid.IBPB',
      'cpuid.IBRS',
      'cpuid.INVPCID',
      'cpuid.Intel',
      'cpuid.LAHF64',
      'cpuid.LM',
      'cpuid.MISALIGNED_SSE',
      'cpuid.MMXEXT',
      'cpuid.MOVBE',
      'cpuid.MWAIT',
      'cpuid.NX',
      'cpuid.PCID',
      'cpuid.PCLMULQDQ',
      'cpuid.PDPE1GB',
      'cpuid.POPCNT',
      'cpuid.PSN',
      'cpuid.RDRAND',
      'cpuid.RDSEED',
      'cpuid.RDTSCP',
      'cpuid.RTM',
      'cpuid.SMAP',
      'cpuid.SMEP',
      'cpuid.SS',
      'cpuid.SSE3',
      'cpuid.SSE41',
      'cpuid.SSE42',
      'cpuid.SSE4A',
      'cpuid.SSSE3',
      'cpuid.STIBP',
      'cpuid.SVM',
      'cpuid.SVM_DECODE_ASSISTS',
      'cpuid.SVM_FLUSH_BY_ASID',
      'cpuid.SVM_NPT',
      'cpuid.SVM_NRIP',
      'cpuid.SVM_VMCB_CLEAN',
      'cpuid.TBM',
      'cpuid.VIA',
      'cpuid.VMX',
      'cpuid.XCR0_MASTER_SSE',
      'cpuid.XCR0_MASTER_YMM_H',
      'cpuid.XOP',
      'cpuid.XSAVE',
      'cpuid.XSAVEOPT',
      'hv.capable',
      'misc.cpuidFaulting',
      'vpmc.fixctr.0',
      'vpmc.fixedWidth',
      'vpmc.genWidth',
      'vpmc.genctr.0',
      'vpmc.genctr.1',
      'vpmc.genctr.2',
      'vpmc.genctr.3',
      'vpmc.microarchitecture.ivybridge',
      'vpmc.numFixedCtrs',
      'vpmc.numGenCtrs',
      'vpmc.version',
      'vt.realmode'
    ]
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
