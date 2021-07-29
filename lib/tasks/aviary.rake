# lib/tasks/aviary.rb
#
# namespace aviary
# The task is written to get the bucket utilization from wasabi of the organizations
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
namespace :aviary do
  desc 'Send an email notification to the organization which dont have active subscription'
  task after_month_notification: :environment do
    puts 'Job started'
    inactive_subscription = Subscription.where(status: :inactive)
    inactive_subscription.each do |subscription|
      organization = subscription.organization
      if (Time.now.to_date - subscription.renewal_date.to_date).zero?
        organization.status = false
        organization.save
      end
      unless organization.status
        if Time.now.to_date - subscription.renewal_date.to_date == 30
          puts "Send notification to: #{organization.name}"
          organization.organization_users.owner.each do |owner|
            OrganizationMailer.inactive_after_month(owner.user, organization).deliver_now
          end
          puts "Notification sent to: #{organization.name}"
        end
      end
    end
    puts 'Job Ended'
  end
  desc 'Delete all the organization data after 45 days of cancellation'
  task delete_organization_data: :environment do
    puts 'Job started'
    inactive_subscription = Subscription.where(status: :inactive)
    inactive_subscription.each do |subscription|
      unless subscription.organization.status
        s3 = Aws::S3::Client.new(
          access_key_id: ENV['WASABI_KEY'],
          secret_access_key: ENV['WASABI_SECRET'],
          region: ENV['WASABI_REGION'],
          endpoint: ENV['WASABI_ENDPOINT']
        )
        if Time.now.to_date - subscription.renewal_date.to_date == 45
          organization = Organization.find(subscription.organization.id)
          bucket_name = organization.bucket_name
          puts "Deleting Organization: #{organization.name}"
          organization.destroy
          objects = s3.list_objects(bucket: bucket_name)
          puts "Total objects in #{bucket_name}: #{objects.contents.size}"
          objects.contents.each do |object|
            s3.delete_object(
              bucket: bucket_name,
              key: object.key
            )
          end
          puts "Bucket #{bucket_name} deleted successfully."
          s3.delete_bucket(bucket: bucket_name)
          puts "Successfully deleted Organization: #{organization.name}"
        end
      end
    end
    puts 'Job Ended'
  end

  desc 'Batch Update Collection S3 Resource File permissions'
  task fix_s3_collection_resource_file_persmissions: :environment do
    puts 'Job started'
    puts 'Only going to update public resources as default permissions is private'

    public_collection_resources = CollectionResourceFile.where(access: :yes).where.not(resource_file_file_size: nil)
    public_collection_resources.each(&:save!)
    puts 'Job Ended'
  end
end
