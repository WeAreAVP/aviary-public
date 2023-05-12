# DeprecatedHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module DeprecatedHelper
  def open(url, _allow_redirections = '')
    res = url =~ URI::DEFAULT_PARSER.make_regexp
    if res.nil?
      File.open(url, allow_redirections: :all, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)

    else
      URI.open(url, allow_redirections: :all, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    end
  end
end
