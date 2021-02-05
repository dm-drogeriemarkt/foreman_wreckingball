# frozen_string_literal: true

module ForemanWreckingball
  class Status < ::HostStatus::Status
    class << self
      def status_name
        const_get('NAME')
      end

      def description
        const_get('DESCRIPTION')
      end

      def host_association
        const_get('HOST_ASSOCIATION')
      end

      def supports_remediate?
        const_defined?('REMEDIATE_ACTION')
      end

      def dangerous_remediate?
        const_defined?('DANGEROUS_REMEDIATE') && const_get('DANGEROUS_REMEDIATE')
      end

      def remediate_action
        supports_remediate? && const_get('REMEDIATE_ACTION')
      end

      def global_ok_list
        const_get('OK_STATUSES')
      end

      def to_global(status)
        return HostStatus::Global::ERROR if const_get('ERROR_STATUSES').include?(status)
        return HostStatus::Global::WARN if const_get('WARN_STATUSES').include?(status)

        HostStatus::Global::OK
      end

      def const_missing(const_name)
        return super unless const_name == :SEARCH

        const_get('SEARCH_VALUES').each_with_object({}) do |(k, v), memo|
          memo[v] = "#{self::HOST_ASSOCIATION.to_s.chomp('_object')} = #{k}"
        end
      end
    end

    def to_label(_options = {})
      self.class.const_get('LABELS').fetch(status, _('Status %s') % status)
    end

    def to_global(_options = {})
      self.class.to_global(status)
    end
  end
end
