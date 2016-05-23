module Syncer

  def self.diff_people(a, b)
    ia = a.index_by(&:email)
    ib = b.index_by(&:email)
    (ia.keys - ib.keys).map { |k| ia[k] }.compact
  end

  class Configurable
    attr_reader :configuration

    def self.from_config(configuration)
      if internal = configuration[internal_configuration_key]
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
      name.gsub("Syncer::", '').gsub("::", ".")
    end

  end

  class Person < Struct.new(:email, :first_name, :last_name)
  end

  class SyncResults < Struct.new(:synced, :failed, :invalid)
  end

  class Runner
  end

  class Source < Configurable

    def syncable_details
      []
    end

  end

  class Destination < Configurable

    def store(list)
      SyncResults.new [], [], list
    end

  end

  module Sources

    class CampaignMonitor < Source

      attr_reader :api_key, :list_id, :client_id

      def configure
        @api_key = configuration.fetch 'api_key'
        @list_id = configuration.fetch 'list_id'
      end

      def syncable_details
      end

    end

  end

  module Destinations

    class Slack < Destination
    end

    class TestFlight < Destination

      attr_reader :email, :password, :app_id

      def configure
        @email = configuration.fetch 'email'
        @password = configuration.fetch 'password'
        @app_id = configuration.fetch 'app_id'

        Spaceship::Tunes.login email, password

      end

      def app
        @app ||= Spaceship::Tunes::Application.find(app_id)
      end

      def store(list)
        existing = app.external_testers.map { |t| Person.new t.email, t.first_name, t.last_name }
        added    = Syncer.diff_people existing, list

        # Now, for the added people, we'll need to correctly push them to testflight...

      end

    end

  end

end
