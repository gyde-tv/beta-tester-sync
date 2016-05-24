module Syncer


  class CampaignMonitorStateSyncer

    attr_reader :api_key, :list_id, :emails, :field, :mapping, :names


    def initialize(api_key, list_id, emails, field, mapping, names = {})
      @api_key = api_key
      @list_id = list_id
      @emails = Array.wrap(emails).map(&:downcase)
      @field = field
      @mapping = mapping
      @names = names
    end

    def sync!
      all_items = all_subcribers_for_list cm_list

      present_and_set = all_items.keys

      correct_values = present_and_set.select { |email| mapping[email] == all_items[email] }

      to_add = (present_and_set + emails - correct_values).reject(&:blank?)
      to_remove = (present_and_set - emails).reject(&:blank?)

      # Now, we handle setting the state on records...

      (to_add + to_remove).uniq.in_groups_of(100, false) do |batch|
        importable = batch.map do |email|
          state = mapping[email]
          name = names[email]
          custom_field = {'Key' => field, 'Value' => state}
          custom_field['Clear'] = true if state.nil?
          {
            'EmailAddress' => email,
            'CustomFields' => [custom_field]
          }.tap do |details|
            details['Name'] = name if name
          end
        end
        result = CreateSend::Subscriber.import cm_auth, list_id, importable, false
      end

    end

    private

    def cm_list
      @cm_list ||= CreateSend::List.new(cm_auth, list_id)
    end

    def cm_auth
      {
        api_key: api_key
      }
    end

    def all_subcribers_for_list(list)
      all_item_key = "[#{field}]"
      last_size = 250
      last_page = 1
      key_values = {}
      while last_size >= 250
        page = list.active "", last_page, 250
        items = page.Results
        items.each do |item|
          email = item.EmailAddress.downcase
          if value = item.CustomFields.find { |f| f.Key == all_item_key || f.Key == field }.try(:Value)
            key_values[email] = value
          else
            key_values[email] = nil
          end
        end
        last_size = items.size
        last_page += 1
      end

      key_values
    end

  end
end
