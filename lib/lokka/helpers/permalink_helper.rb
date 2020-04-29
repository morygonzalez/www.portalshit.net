# frozen_string_literal: true

module Lokka
  module PermalinkHelper
    def custom_permalink?
      RequestStore[:custom_permalink] ||= Option.permalink_enabled == 'true'
    end

    def permalink_format
      RequestStore[:permalink_format] ||= Option.permalink_format
    end

    def custom_permalink_format
      permalink_format.scan(/%(\w+?)%/).flatten
    end

    def custom_permalink_path(param)
      permalink_format.gsub(/%(\w+?)%/) { param[Regexp.last_match(1).to_sym] }
    end

    def custom_permalink_parse(path)
      regexp = Regexp.compile(Regexp.escape(permalink_format).gsub(/\%(\w+?)\%/) { "(?<#{Regexp.last_match(1)}>.+?)" } + '$')
      match_data = regexp.match(path)
      return nil if match_data.nil?

      match_data.names.each_with_object({}) do |key, hash|
        hash[key.to_sym] = match_data[key]
      end
    end

    def custom_permalink_entry(path)
      match_data = custom_permalink_parse(path)
      return nil if match_data.nil?

      if match_data[:id] || match_data[:slug]
        entries = if match_data[:id]
                    Entry.where(id: match_data[:id])
                  elsif match_data[:slug]
                    Entry.where(slug: match_data[:slug])
                  end
        entries.first
      else
        start_date = Time.local(
          match_data[:year],
          match_data[:month]  || 1,
          match_data[:day]    || 1,
          match_data[:hour]   || 0,
          match_data[:minute] || 0,
          match_data[:second] || 0
        )
        end_date = Time.local(
          match_data[:year],
          match_data[:month]  || 12,
          match_data[:day]    || 31,
          match_data[:hour]   || 23,
          match_data[:minute] || 59,
          match_data[:second] || 59
        )
        Entry.where(created_at: (start_date..end_date)).first
      end
    end

    def custom_permalink_fix(path)
      result = custom_permalink_parse(path)

      url_changed = false
      %i[year month monthnum day hour minute second].each do |key|
        i = (key == :year ? 4 : 2)
        if result[key] && result[key].size < i
          result[key] = result[key].rjust(i, '0')
          url_changed = true
        end
      end

      custom_permalink_path(result) if url_changed
    rescue StandardError => _e
      nil
    end

    class << self
      include Lokka::PermalinkHelper
    end
  end
end
