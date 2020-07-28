class Figgy
  class Root
    @handlers = []

    class << self
      attr_accessor :handlers
    end

    def initialize(source, path)
      @source = source
      @path = path
    end
  end

  class VaultRoot < Root
    def initialize(source, path)
      super
    end

    def fetch(overlay, config_key)
      secret = @source.logical.read(File.join(@path, overlay.to_s, config_key))
      secret ? [JSON.parse(secret.data.to_json)] : nil
    end

    def config_values(overlay)
      @source.logical.list(File.join(@path, overlay.to_s)).reject { |v| v.end_with?('/') }
    end
  end

  class FileRoot < Root
    def initialize(source, path)
      super
    end

    def fetch(overlay, config_key)
      files_for(File.join(overlay.to_s, config_key)).map do |f|
        handler_for(f).call(File.read(f))
      end
    end

    def config_values(overlay)
      files_for(File.join(overlay.to_s, '*')).map do |f|
        File.basename(f).sub(/\..+$/, '')
      end
    end

    private

    def handler_for(path)
      match = Root.handlers.find { |ext, handler| path =~ /\.#{ext}$/ }
      match && match.last
    end

    def files_for(name)
      extensions = Root.handlers.map(&:first)
      globs = extensions.map { |ext| "#{name}.#{ext}" }
      filepaths = globs.map { |glob| File.join(@path, glob) }.flatten.uniq

      Dir[*filepaths]
    end
  end
end
