module VsphereOsIdentifiers
  class Os
    attr_reader :id, :description, :architecture, :since, :osfamily, :major, :name

    def initialize(id, opts = {})
      @id = id.to_s
      @description = opts.fetch(:description, nil)
      @architecture = opts.fetch(:architecture, nil)
      @since = opts.fetch(:since, nil)
      @osfamily = opts.fetch(:osfamily, nil)
      @name = opts.fetch(:name, nil)
      @major = opts.fetch(:major, nil)
    end

    def ==(other)
      other.class == self.class && other.id == id
    end
  end
end
