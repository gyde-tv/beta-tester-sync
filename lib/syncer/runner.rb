require_relative './base'
require_relative './source'
require_relative './destination'

module Syncer

  class Runner

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def run
      sources = Syncer.sources.map { |s| s.from_config(configuration) }.compact
      people = people_from_sources sources

      # TODO: Log the number of people...

      destinations = Syncer.destinations.map { |d| d.from_config(configuration) }.compact


      destinations.each do |destination|
        destination.store people
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
