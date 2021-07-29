# lib/tasks/ohms_xsd_checker.rake
#
# namespace aviary
# The task is written to send notification when there is a change in xsd at http://weareavp.com/nunncenter/ohms/ohms.xsd
#
# Author::    Nouman Tayyab (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
namespace :aviary do
  namespace :ohms_xsd_checker do
    desc 'Trigger the job to check if there is a change in ohms.xsd at nunncenter'
    task start: :environment do
      include ApplicationHelper
      begin
        # getting latest ohms.xsd from folder ohms xsd
        latest_xsd = File.read("#{Rails.root}/public/ohms xsd/ohms.xsd")
        # getting ohms.xsd from nunncenter
        nunncenter_xsd = open(nunncenter_ohms_xsd).read
        unless xml_cmp(latest_xsd, nunncenter_xsd)
          UserMailer.ohms_xsd_changed.deliver_now
        end
      rescue StandardError
        puts 'Error found in XSD file.'
      end
    end

    def xml_cmp(xml1, xml2)
      a = REXML::Document.new(xml1.to_s)
      b = REXML::Document.new(xml2.to_s)
      normalized = Class.new(REXML::Formatters::Pretty) do
        def write_text(node, output)
          super(node.to_s.strip, output)
        end
      end
      normalized.new(0, false).write(a, a_normalized = '')
      normalized.new(0, false).write(b, b_normalized = '')
      a_normalized == b_normalized
    end
  end
end
