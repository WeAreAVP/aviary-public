require 'rails/generators'
require 'rails/generators/active_record'
# CustomFieldsGenerator
class CustomFieldsGenerator < ActiveRecord::Generators::Base
  # ActiveRecord::Generators::Base inherits from Rails::Generators::NamedBase
  # which requires a NAME parameter for the new table name.
  argument :name, type: :string, default: 'dummy'

  class_option :'skip-migration', type: :boolean, desc: "Don't generate a migration for the dynamic attributes table"
  class_option :'skip-initializer', type: :boolean, desc: "Don't generate an initializer"

  source_root File.expand_path('../../custom_fields', __FILE__)

  def copy_files
    return if options['skip-migration']
    migration_template 'migrations/field_manager.rb', 'db/migrate/create_field_manager.rb'
    migration_template 'migrations/field_setting.rb', 'db/migrate/create_field_settings.rb'
    migration_template 'migrations/field_values.rb', 'db/migrate/create_field_values.rb'
  end

  def create_initializer
    return if options['skip-initializer']
    copy_file 'initializer.rb', 'config/initializers/custom_fields.rb'
  end
end
