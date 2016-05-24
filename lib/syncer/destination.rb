require_relative './base'
require 'spaceship'

module Syncer

  def self.destinations
    [Syncer::Destinations::Slack, Syncer::Destinations::TestFlight]
  end

  class Destination < Configurable

    def store(list)
      SyncResults.new [], [], list
    end

    def synced?(person)
      person.synced[self.class.service_key]
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

        requires_syncing = list.reject { |l| synced? l }

        existing = app.external_testers.map { |t| Person.new email: t.email, first_name: t.first_name, last_name: t.last_name }
        added    = Syncer.diff_by requires_syncing, list, &:email


        # TODO: COnfirm the added...
        p added

        # Now, for the added people, we'll need to correctly push them to testflight...

      end

    end

  end


end
