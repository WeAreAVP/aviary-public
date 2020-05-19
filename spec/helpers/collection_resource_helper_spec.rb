require 'rails_helper'


RSpec.describe CollectionResourceHelper, type: :helper do
  describe 'Advance Search Helper' do
    it 'validate display_field_title_table' do
      expect(helper.display_field_title_table('title_ss')).to be_a_kind_of(String)
    end

    it 'validate display_field_title_table' do
      expect(helper.display_field_title_table('resource_file_count_ss')).to be_a_kind_of(String)
    end

  end
end
