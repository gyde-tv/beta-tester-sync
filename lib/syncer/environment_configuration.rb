module Syncer
  class EnvironmentConfiguration

    KEYSPACE_SEPERATOR = "__"

    attr_reader :env_prefix

    def initialize
      @env_prefix = "SYNCER"
    end

    def to_env(config)
      {}.tap do |out|
        normalize_subkeys! config, out
      end
    end

    def dump_env!(config)
      env = to_env(config)
      if env.any?
        puts "#{env.map { |k,v| "#{k}=#{v}" }.join("\n")}"
      end
    end

    def normalize_subkeys!(input, out, path = [])
      input.each do |key, value|
        if value.is_a?(Hash)
          normalize_subkeys! value, out, path + [key.upcase]
        else
          full_key = [env_prefix.upcase, *path, key.upcase].join(KEYSPACE_SEPERATOR)
          out[full_key] = value.to_s
        end
      end

    end

    def from_env(env = ENV)

      output = {}

      prefix_regexp = /\A#{Regexp.escape(env_prefix)}_+/

      env.each do |key, value|
        if key =~ prefix_regexp
          keyspace = key.gsub(prefix_regexp, '').split(KEYSPACE_SEPERATOR).map(&:downcase)
          last = keyspace.pop
          target = keyspace.inject(output) { |o,k| o[k] ||= {} }
          target[last] = value
        end
      end

      output
    end

  end
end
