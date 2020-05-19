module CustomFields
  # ActiveRecord
  module ActiveRecord
    def custom_fields?
      include CustomFields::HasCustomFields
    end
  end
end

ActiveRecord::Base.extend CustomFields::ActiveRecord
