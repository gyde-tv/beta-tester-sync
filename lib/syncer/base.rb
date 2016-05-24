require 'logger'

module Syncer

  def self.logger
    @_logger ||= Logger.new(STDOUT)
  end

  def self.diff_by(a, b, &field)
    ia = Hash[a.map { |v| [field.call(v), v]} ]
    ib = Hash[b.map { |v| [field.call(v), v]} ]
    (ia.keys - ib.keys).map { |k| ia[k] }.compact
  end

  class Configurable
    attr_reader :configuration

    def logger; Syncer.logger; end
    def service_key; self.class.service_key; end

    def self.from_config(configuration)
      parts = internal_configuration_key.split(".")
      if internal = parts.inject(configuration) { |c, k| (c || {})[k] }
        return nil if internal['enabled'].to_s == 'false'
        new internal
      else
        nil
      end
    end

    def initialize(configuration)
      @configuration = configuration
      configure
    end

    def configure
      # Do nothing here, in parent classes this will extract out configuration hash options
      # and assign them properly to child attributes.
    end

    def self.internal_configuration_key
      name.gsub("Syncer::", '').gsub("::", ".").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    end

    def self.service_key
      @service_key ||= internal_configuration_key.split(".").last
    end

  end

  class Person < Struct.new(:email, :first_name, :last_name, :synced)

    def initialize(options = {})
      super options.fetch(:email), options[:first_name], options[:last_name], (options[:synced] || {})
    end

    def merge!(other)
      raise ArgumentError.new("invalid other person") unless other.email == email
      other.synced.each_pair do |key, value|
        synced[key] ||= value
      end
    end

  end

  class SyncResults < Struct.new(:service, :synced, :failed, :ignored)

    def to_sync_hash
      (synced + ignored).each_with_object({}) do |i, o|
        o[i.email] = {service => true}
      end
    end

  end

end
