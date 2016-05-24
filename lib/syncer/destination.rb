require_relative './base'
require 'spaceship'
require 'slack'

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

      attr_reader :token, :client

      def configure
        @token = configuration.fetch 'token'
        @client = ::Slack::Client.new(token: token)
      end

      def store(list)

        added = []
        issues = []
        already_present = []

        logger.info "[Slack] manually syncing #{list.size} people"

        list.each do |person|
          response = client.post 'users.admin.invite', email: person.email, set_active: true
          if response['ok']
            added << person
            logger.info "[Slack] synced #{person.email}"
          elsif response['error'] == 'already_in_team' || response['error'] == 'already_invited'
            already_present << person
            logger.error "[Slack] Couldn't sync #{person.email} as they're already in the room..."
          else
            issues << person
            logger.error "[Slack] unknown error on #{person.email}: #{response['error']}"
          end
        end

        logger.info "[Slack] Done!"

        SyncResults.new self.class.service_key, added, issues, already_present
      end


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

        logger.info "[TestFlight] fetching external testers..."
        existing = app.external_testers.map { |t| Person.new email: t.email, first_name: t.first_name, last_name: t.last_name }

        added    = Syncer.diff_by requires_syncing, existing, &:email
        already_exists = list - added

        logger.info "[TestFlight] Of #{list.size} to sync, we only need to push #{added.size} as #{already_exists.size} exist."

        issues = []
        successful = []

        added.each do |person|
          begin
            app.add_external_tester! email: person.email, first_name: person.first_name, last_name: person.last_name
            successful << person
            logger.info "[TestFlight] synced #{person.email}"
          rescue => e
            logger.error "[TestFlight] failed to sync #{person.email}, error: #{e}"
            issues << person
          end
        end

        logger.info "[TestFlight] Done!"

        SyncResults.new self.class.service_key, successful, issues, already_exists
      end

    end

  end



end
