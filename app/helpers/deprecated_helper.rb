# DeprecatedHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module DeprecatedHelper
    def open(url, allow_redirections="")
      res = url =~ URI::regexp 
      if res.nil?
        return File.open(url, allow_redirections: :all, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  
      else
        return URI.open(url, allow_redirections: :all, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      end
    end  
  end
  