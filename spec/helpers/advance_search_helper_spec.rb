require 'rails_helper'


RSpec.describe AdvanceSearchHelper, type: :helper do
  describe 'Advance Search Helper' do
    subject { { "1007d4da6ce12c10044a35c7da28a1ff" =>
                    { "search_field" => "advanced",
                      "commit" => "Search",
                      "op" => "",
                      "type_of_search" => "simple",
                      "keywords" => "dora and salo",
                      "type_of_field_selector_single" => "keywords",
                      "utf8" => "✓" } } }
    
    it 'validate advance_search_query_only' do
      searched_keywords = subject
      expect(AdvanceSearchHelper::advance_search_query_only(searched_keywords, false, search_type = 'search_type=simple', [])).to eq("dora and salo")
    end
    
    it 'validate advance_search_query_only' do
      searched_keywords = subject
      tester = AdvanceSearchHelper::advance_search_query_only(searched_keywords, true, search_type = 'search_type=simple', [])
      expect(tester).to eq({ "69db31976ead37b85cc42a49c95fd06eec99cfd9b7ff219a25c0f59cb4049343" => "dora", "b7d6959b30ebde6b9ecab937804df451449ecd2b2d98e967c50cd57481a56ce7" => "salo", "6201111b83a0cb5b0922cb37cc442b9a40e24e3b1ce100a4bb204f4c63fd2ac0" => "and" })
    end
    
    it 'validate multiple_search_simplifier' do
      searched_keywords = subject
      tester = helper.multiple_search_simplifier(searched_keywords)
      expect(tester).to be_a_kind_of(Array)
    end
    
    it 'validate advance_search_string' do
      searched_keywords = subject
      searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"]["type_of_search"] = 'endswith'
      tester = helper.advance_search_string(searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"])
      expect(tester).to be_a_kind_of(String)
    end
    
    it 'validate advance_search_string' do
      searched_keywords = subject
      searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"]["type_of_search"] = 'wildcard'
      tester = helper.advance_search_string(searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"])
      expect(tester).to be_a_kind_of(String)
    end
    
    it 'validate advance_search_string' do
      searched_keywords = subject
      searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"]["type_of_search"] = 'startswith'
      tester = helper.advance_search_string(searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"])
      expect(tester).to be_a_kind_of(String)
    end
    
    it 'validate advance_search_string' do
      searched_keywords = subject
      searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"]["keywords"] = 'dor*'
      tester = helper.advance_search_string(searched_keywords["1007d4da6ce12c10044a35c7da28a1ff"])
      expect(tester).to be_a_kind_of(String)
    end
  end
end
