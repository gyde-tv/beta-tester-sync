require_relative './base'
require 'createsend'

module Syncer

  def self.sources
    [Syncer::Sources::CampaignMonitor]
  end

    class Source < Configurable

      def store(list)
      end

      def syncable_details
        []
      end

    end


    module Sources

      class CampaignMonitor < Source

        attr_reader :api_key, :list_id

        def configure
          @api_key = configuration.fetch 'api_key'
          @list_id = configuration.fetch 'list_id'
        end

        def auth
          @auth ||= {api_key: api_key}
        end

        def syncable_details
          logger.info "[CM] Fetching list..."
          list = CreateSend::List.new(auth, list_id)

          people = []

          logger.info "[CM] Walking list members..."
          walk list do |item|
            flags = extract_flags item
            people << Person.new(email: item.EmailAddress, synced: flags)
          end

          logger.info "[CM] Done!"

          people
        end

        def store(list)
          logger.info "[CM] Updating details for #{list.size} people"
          list.each do |person|
            subscriber = CreateSend::Subscriber.get auth, list_id, person.email
            normalized = normalize_flags person
            next if normalized.empty?
            logger.info "[CM] updating #{person.email} (#{subscriber.Name}) flags to #{normalized.inspect}"
            updateable = CreateSend::Subscriber.new auth, list_id, person.email
            updateable.update person.email, subscriber.Name, normalized, false
          end
        end

        private

        def normalize_flags(person)
          person.synced.to_a.map do |(key, value)|
            {
              "Key" => "synced.#{key}",
              "Value" => value.to_s
            }
          end
        end

        def extract_flags(item)
          out = {}
          (item.CustomFields || []).each do |item|
            if item.Key =~ /\A\[synced\.(\w+)\]\Z/
              out[$1] = (item.Value == 'true')
            end
          end
          out
        end

        def walk(list)
          last_size = 250
          last_page = 1
          key_values = {}
          while last_size >= 250
            page = list.active "", last_page, 250
            items = page.Results
            items.each do |item|
              yield item if block_given?
            end
            last_size = items.size
            last_page += 1
          end
        end

      end

    end

end
