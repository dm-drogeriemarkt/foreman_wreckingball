module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Real
        extend ActiveSupport::Concern

        module Overrides
          def host_attributes(host, filters)
            {
              datacenter:      filters[:datacenter],
              cluster:         filters[:cluster],
              name:            host[:name],
              cpu_cores:       host.hardware.cpuInfo.numCpuCores,
              cpu_sockets:     host.hardware.cpuInfo.numCpuPackages,
              cpu_threads:     host.hardware.cpuInfo.numCpuThreads,
              memory:          host.hardware.memorySize,
              uuid:            host.hardware.systemInfo.uuid,
              model:           host.hardware.systemInfo.model,
              vendor:          host.hardware.systemInfo.vendor,
              ipaddress:       (host.config.network.vnic.first.spec.ip.ipAddress rescue nil),
              ipaddress6:      (host.config.network.vnic.first.spec.ip.ipV6Config.ipV6Address.first.ipAddress rescue nil),
              product_name:    host.summary.config.product.name,
              product_version: host.summary.config.product.version,
              hostname:        (host.config.network.dnsConfig.hostName rescue nil),
              domainname:      (host.config.network.dnsConfig.domainName rescue nil),
              vm_ids:          Proc.new { host[:vm].map {|vm| vm.config.instanceUuid } }
            }
          end
        end

        included do
          prepend Overrides
        end
      end
    end
  end
end
