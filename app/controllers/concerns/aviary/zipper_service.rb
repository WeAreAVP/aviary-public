# app/controllers/concerns/aviary/zipper_service.rb
#
# Module Aviary::ZipperService
# The module is written to get the youtube close captions
# and store it as transcript
#
# Author::  Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.

# Zipper Service
module Aviary::ZipperService
  extend ActiveSupport::Concern
  attr_accessor :tmp_user_folder

  private

  def process_and_create_zip_file(files, _file_path, return_path = false)
    begin
      FileUtils.mkdir_p(tmp_user_folder) unless Dir.exist?(tmp_user_folder)
      files.each do |filename|
        create_zip_from_tmp_folder(tmp_user_folder, filename)
      end
      if return_path
        return "#{tmp_user_folder}.zip"
      end
      zip_data = File.read("#{tmp_user_folder}.zip")
    ensure
      unless return_path
        FileUtils.rm_rf([tmp_user_folder, "#{tmp_user_folder}.zip"])
      end
    end
    zip_data
  end

  def create_zip_from_tmp_folder(tmp_user_folder, filename)
    require 'zip'
    Zip::File.open("#{tmp_user_folder}.zip", Zip::File::CREATE) do |zf|
      zf.add(filename, "#{tmp_user_folder}/#{filename}")
    end
  end
end
