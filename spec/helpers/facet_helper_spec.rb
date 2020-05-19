require 'rails_helper'


RSpec.describe FacetHelper, type: :helper do
  describe 'validate FacetHelper' do
    it 'validate add_facet_params_to_url' do
      tester = helper.add_facet_params_to_url('/catalog?q=&search_field=all_fields&search_type=simple&utf8=%E2%9C%93', { "all" => { 'test' => %i'test test1' }, "range" => { 'test' => %i'test test1' } })
      expect(tester).to be_a_kind_of(String)
    end
  
  end
end
