require_relative './base'
require 'createsend'

module Syncer

  def self.sources
    [Syncer::Sources::CampaignMonitor]
  end

    class Source < Configurable

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

        def syncable_details
          list = CreateSend::List.new({api_key: api_key}, list_id)

          people = []

          walk list do |item|
            flags = extract_flags item
            people << Person.new(email: item.EmailAddress, synced: flags)
          end

          people
        end

        private

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
