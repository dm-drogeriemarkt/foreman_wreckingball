# frozen_string_literal: true

class UpdateHostsVmwareFacets < ApplicationJob
  after_perform do
    self.class.set(:wait => 12.hours).perform_later
  end

  def perform; end
end
