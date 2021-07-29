# services/aviary/import_csv.rb
#
# Module Aviary::ImportCsv
# The module is written to import csv file
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # ImportCsv
  class ImportCsv
    def process(file_data)
      if ['text/csv', 'application/octet-stream', 'text/plain'].include?(file_data.content_type)
        begin
          csv = CSV.read(file_data.path, headers: true, encoding: 'ISO8859-1:utf-8')
          global_ip = []
          csv.each do |row|
            csv_hash = row.to_hash
            ip = csv_hash['IP or IP Range']
            label = csv_hash['Label']
            global_ip << { id: ip, value: label, type: :collection_global_ip_list } if check_valid_ip?(ip)
          end
          global_ip.count.zero? ? 'Unable to read any valid IP from the file.' : global_ip
        rescue StandardError
          'Unable to read file.'
        end
      else
        'Not a valid CSV file.'
      end
    end

    def check_valid_ip?(ip_address)
      IPAddr.new(ip_address)
    rescue StandardError
      false
    end
  end
end
