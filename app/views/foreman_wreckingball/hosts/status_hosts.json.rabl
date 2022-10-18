# frozen_string_literal: true

object false

node(:recordsTotal) { @count }
node(:recordsFiltered) { @count }
node(:data) do
  partial 'foreman_wreckingball/hosts/_hosts', object: @hosts,
    locals: {
      host_association: @status.host_association,
      supports_remediate: @status.supports_remediate?,
    }
end
