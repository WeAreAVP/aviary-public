# Aviary::General
# services/aviary/general/general.rb
#
# Module Aviary::General
#
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # General class
  class General
    def random_string
      o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
      (0...50).map { o[rand(o.length)] }.join
    end

    def encoded_random_string
      Digest::SHA1.hexdigest random_string
    end

    def date_handler_helper(value)
      begin
        value = value.blank? ? '' : value.strip
        case value.scan(/(?=-)/).count
        when 0
          value += '-01-01'
        when 1
          value += '-01'
        end
        begin
          Date.parse(value)
          value = value.to_time.utc.to_i
        rescue ArgumentError
          value = ''
        end
      rescue ArgumentError
        value = ''
      end
      value.to_s
    end
  end
end
