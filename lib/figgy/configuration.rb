class Figgy
  class Configuration
    # The directories in which to search for configuration files
    attr_reader :roots

    # The list of defined overlays
    attr_reader :overlays

    # Whether to reload a configuration file each time it is accessed
    attr_accessor :always_reload

    # Whether to load all configuration files upon creation
    # @note This does not prevent +:always_reload+ from working.
    attr_accessor :preload

    # Whether to freeze all loaded objects. Useful in production environments.
    attr_accessor :freeze

    # Constructs a new {Figgy::Configuration Figgy::Configuration} instance.
    #
    # By default, uses a +root+ of the current directory, and defines handlers
    # for +.yml+, +.yaml+, +.yml.erb+, +.yaml.erb+, and +.json+.
    def initialize
      @roots    = [FileRoot.new(File, Dir.pwd)]
      @always_reload = false
      @preload = false
      @freeze = false

      define_handler 'yml', 'yaml' do |contents|
        YAML.load(contents)
      end

      define_handler 'yml.erb', 'yaml.erb' do |contents|
        erb = ERB.new(contents).result
        YAML.load(erb)
      end

      define_handler 'json' do |contents|
        JSON.parse(contents)
      end

      @overlays = [Overlay.new('root', nil, @roots)]
    end

    # Sets the +root+ to a Vault client, rooted at the given path.
    #
    # @see #root=
    def vault_root(vault, path)
      @roots = [VaultRoot.new(vault, path)]
      @overlays = [Overlay.new('root', nil, @roots)]
    end

    # Sets the +root+ to the given file directory.
    #
    # @see #vault_root
    def root=(path)
      @roots = [FileRoot.new(File, File.expand_path(path))]
      @overlays = [Overlay.new('root', nil, @roots)]
    end

    # Adds a Vault client +root+, rooted at the given path.
    #
    # @see #add_root
    def add_vault_root(vault, path)
      new_root = VaultRoot.new(vault, path)

      @roots.unshift new_root
      @overlays.each { |o| o.roots = @roots }
    end

    # Adds a +root+ at the given file directory.
    #
    # @see #add_vault_root
    def add_root(path)
      new_root = FileRoot.new(File, File.expand_path(path))

      @roots.unshift new_root
      @overlays.each { |o| o.roots = @roots }
    end

    # @see #always_reload=
    def always_reload?
      !!@always_reload
    end

    # @see #preload=
    def preload?
      !!@preload
    end

    # @see #freeze=
    def freeze?
      !!@freeze
    end

    # Adds a new handler for files with any extension in +extensions+.
    #
    # @example Adding an XML handler
    #   config.define_handler 'xml' do |body|
    #     Hash.from_xml(body)
    #   end
    def define_handler(*extensions, &block)
      Figgy::Root.handlers += extensions.map { |ext| [ext, block] }
    end

    # Adds an overlay named +name+, found at +value+.
    #
    # If a block is given, yields to the block to determine +value+.
    #
    # @param name an internal name for the overlay
    # @param value the value of the overlay
    # @example An environment overlay
    #   config.define_overlay(:environment) { Rails.env }
    def define_overlay(name, value = nil)
      value = yield if block_given?

      @overlays << Overlay.new(name, value, @roots)
    end
  end
end
