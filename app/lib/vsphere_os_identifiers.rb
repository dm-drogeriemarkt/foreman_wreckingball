# frozen_string_literal: true

module VsphereOsIdentifiers
  def self.data
    @data ||= load_data
  end

  def self.lookup(id)
    entry = data[id.to_s]
    VsphereOsIdentifiers::Os.new(id, entry) if entry
  end

  def self.load_data
    YAML.load_file(File.expand_path('vsphere_os_identifiers/data.yaml', __dir__))
  end

  def self.all
    data.map { |os, _| lookup(os) }
  end

  def self.where(selectors = {})
    found = all

    selectors.each do |selector, value|
      next unless selectors.key?(selector) && !value.nil?

      found.select! { |os| os.public_send(selector) && [os.public_send(selector)].flatten.include?(value) }
    end
    found
  end

  def self.find_by(selectors = {})
    result = where(selectors)
    return unless result.any?
    result.first
  end
end
