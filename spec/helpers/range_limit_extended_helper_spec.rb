require 'rails_helper'

RSpec.describe RangeLimitExtendedHelper, type: :helper do
  let(:arguments) {{utf8: '✓', q: '', search_field: 'all_fields', range: {"description_date_search_lms" => {"begin" => '08-11-2018 - 08-11-2018', "end" => '08-11-2018'}}, commit: 'Limit', controller: 'catalog', action: 'index'}}
  describe '#range_display' do
    it 'should return string' do
      expect(helper.range_display('description_date_search_lms', arguments)).not_to be_empty
    end
  end

  describe '#range_display' do
    it 'should return string' do
      expect(helper.render_range_input('description_date_search_lms', :begin, 'render_range_input')).not_to be_empty
    end
  end
end