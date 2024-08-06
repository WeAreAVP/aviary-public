# services/aviary/file_manager.rb
#
# Module Aviary::FileManager
# The module is written for creating folder and temporary files
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # Class for manging file creation and deletion
  class FileManager
    def create_file(base_path, file_url, expiry_url)
      uri = URI.parse(file_url)
      file_name = "#{Time.now.to_i}_#{File.basename(uri.path)}"
      link_to_file = expiry_url.blank? ? file_url : expiry_url
      system('cd ' + base_path + ' && wget -O ' + file_name + ' "' + link_to_file + '"')
      "#{base_path}/#{file_name}"
    end

    def delete_file(path)
      FileUtils.rm_rf(path) if File.exist?(path)
    end
  end
end
