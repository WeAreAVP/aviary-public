#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
Rails.configuration.email_template_information = YAML.load_file(Rails.root.join('config','template_information.yml'))
Rails.configuration.default_fields = YAML.load_file(Rails.root.join('config','default_fields.yml'))
