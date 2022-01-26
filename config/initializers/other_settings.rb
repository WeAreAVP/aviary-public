#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
STORAGE_FOR_ATTACHMENTS = {
  storage: :s3,
  s3_region: ENV['WASABI_REGION'],
  s3_permissions: :private,
  s3_protocol: :https,
  url: ':s3_domain_url',
  s3_host_alias: ENV['WASABI_HOSTNAME'],
  path: '/:class/:attachment/:id_partition/:style/:filename',
  s3_host_name: ENV['WASABI_HOSTNAME'],
  s3_options: {
    endpoint: ENV['WASABI_ENDPOINT'],
    force_path_style: true
  },
  s3_credentials:{
    access_key_id: ENV['WASABI_KEY'],
    secret_access_key: ENV['WASABI_SECRET']
  },
  #TODO: Need to remove bucket proc from here, Move it into a service.
  bucket: proc { |attachment| attachment.instance.set_bucket }
}

USE_STORAGE_PARAMS_FOR_ATTACHMENTS = Rails.env == 'production'