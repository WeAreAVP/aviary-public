# services/aviary/media_manager.rb
#
# Module Aviary::MediaManager
# The module is written to map and store the media related info in the Aviary system
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.

module Aviary
  # MediaManager Class for managing and mapping the resource information
  class MediaManager
    def ffmpeg_info(file_path)
      metadata = []
      stdin, stdout, stderr, wait_thr = Open3.popen3('ffmpeg', '-i', file_path)
      std_output = stderr.gets(nil)
      stdin.close
      stdout.close
      stderr.close
      wait_thr.value
      begin
        metadata = std_output.split("\n")
        std_error = ''
      rescue MultiJson::ParseError
        std_error = 'Enable to process the output of mediainfo'
      end
      [metadata, std_error]
    end
  end
end
