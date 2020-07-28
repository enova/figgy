class Figgy
  class Finder
    def initialize(config)
      @config = config
    end

    # Searches for files defining the configuration key +name+, merging each
    # instance found with the previous. In this way, the overlay configuration
    # at +production/foo.yml+ can override values in +foo.yml+.
    #
    # If the contents of the file were a Hash, Figgy will translate it into
    # a {Figgy::Hash Figgy::Hash} and perform deep-merging for all overlays. This
    # allows you to override only a single key deep within the configuration, and to
    # access it using dot-notation, symbol keys or string keys.
    #
    # @param [String] name the configuration file to load
    # @return Whatever was in the config file loaded
    # @raise [Figgy::FileNotFound] if no config file could be found for +name+
    def load(name)
      unless all_key_names.include?(name)
        raise(Figgy::FileNotFound, "Can't find config files for key: #{name.inspect}")
      end

      all_data = @config.overlays.reduce([]) do |result, o|
        result += o.load(name)
      end

      final_result = all_data.reduce(nil) do |result, data|
        if result && result.respond_to?(:merge)
          deep_merge(result, data)
        else
          data
        end
      end

      deep_freeze(to_figgy_hash(final_result))
    end

    # @return [Array<String>] the names of all unique configuration keys
    def all_key_names
      @config.overlays.map { |overlay| overlay.all_keys }.flatten.uniq
    end

    private

    def to_figgy_hash(obj)
      case obj
      when ::Hash
        obj.each_pair { |k, v| obj[k] = to_figgy_hash(v) }
        Figgy::Hash.new(obj)
      when Array
        obj.map { |v| to_figgy_hash(v) }
      else
        obj
      end
    end

    def deep_freeze(obj)
      return obj unless @config.freeze?
      case obj
      when ::Hash
        obj.each_pair { |k, v| obj[deep_freeze(k)] = deep_freeze(v) }
      when Array
        obj.map! { |v| deep_freeze(v) }
      end
      obj.freeze
    end

    def deep_merge(a, b)
      a.merge(b) do |key, oldval, newval|
        oldval.respond_to?(:merge) && newval.respond_to?(:merge) ? deep_merge(oldval, newval) : newval
      end
    end
  end
end
