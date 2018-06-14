# frozen_string_literal: true

module ForemanWreckingball
  module HypervisorsHelper
    def wreckingball_spectre_v2_status(vmware_hypervisor_facet)
      if vmware_hypervisor_facet.feature_capabilities.blank?
        icon_text('unknown', '', kind: 'pficon', title: _('N/A'))
      elsif vmware_hypervisor_facet.provides_spectre_features?
        icon_text('ok', '', kind: 'pficon', title: _('CPU-Features are present on this host.'))
      else
        icon_text('error-circle-o', '', kind: 'pficon', title: _('Required CPU features are missing. This host is most likely vulnerable.'))
      end
    end
  end
end
