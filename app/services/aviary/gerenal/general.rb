# Aviary::General
# services/aviary/general/general.rb
#
# Module Aviary::General
#
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
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
  end
end
