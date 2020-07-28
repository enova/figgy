class Figgy
  class Overlay
    # Internal name of the overlay, like +:environment+
    attr_accessor :name

    # The namespace (path) to search in, like +:staging+
    attr_reader :namespace

    # Roots to start searching from.
    attr_accessor :roots

    def initialize(name, namespace, roots)
      @name = name
      @namespace = namespace
      @roots = Array(roots)
    end

    # Load all values for the given config +name+ at this overlay level.
    #
    # @return [Array<Object>] all found configuration data for +name+, in root precedence order
    def load(name)
      @roots.reduce([]) do |result, root|
        value = root.fetch(@namespace, name)
        result += value if value
        result
      end
    end

    # @return [Array<String>] the names of all existing configuration keys at this overlay level
    def all_keys
      @roots.map { |r| r.config_values(@namespace) }.flatten.uniq
    end
  end
end
