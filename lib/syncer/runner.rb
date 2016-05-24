require_relative './base'
require_relative './source'
require_relative './destination'

require 'open-uri'

module Syncer

  class Runner

    def logger; Syncer.logger; end

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def run

      logger.info "Starting sync run..."

      sources = Syncer.sources.map { |s| s.from_config(configuration) }.compact

      logger.info "Sources: #{sources.map(&:service_key).join(", ")}"

      people = people_from_sources sources

      logger.info "Found #{people.size} people in the run who need to be synced."

      destinations = Syncer.destinations.map { |d| d.from_config(configuration) }.compact
      logger.info "Destinations: #{destinations.map(&:service_key).join(", ")}"


      outer_results = []

      destinations.each do |destination|
        logger.info "Syncing to destination #{destination.service_key}"
        result = destination.store(people)

        outer_results << result

        logger.info "Syncing to #{destination.service_key}, synced=#{result.synced.size} failed=#{result.failed.size} ignored=#{result.ignored.size}"
      end

      logger.info "Flattening, preparing to propagate status to the sources..."
      flattened = Hash.new { |h,email| h[email] = {} }

      outer_results.each do |item|
        item.to_sync_hash.each do |email, synced|
          flattened[email].merge! synced
        end
      end

      logger.info "Calculating what needs to be synced back to the sources"
      write_back = []
      people.each do |person|
        if changes = flattened.fetch(person.email, nil)
          alternative = Person.new email: person.email, synced: changes
          person.merge! alternative
          write_back << person
        end
      end

      if write_back.any?
        logger.info "Writing back #{write_back.size} people."
        sources.each do |source|
          logger.info "Writing back to #{source.service_key}"
          source.store write_back
        end
      else
        logger.info "Nothing to write back, we're a-ok!"
      end

      perform_healthcheck


    end

    def perform_healthcheck
      if url = configuration['checkin_url']
        logger.info "Performing checkin..."
        open(url).read
      end
    end

    def people_from_sources(sources)
      people = {}
      sources.each do |source|
        source.syncable_details.each do |person|
          if existing = people[person.email]
            existing.merge! person
          else
            people[person.email] = person
          end
        end
      end

      people.values.sort_by(&:email)
    end

  end

end
