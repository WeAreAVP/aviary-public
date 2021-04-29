require 'rails_helper'


RSpec.describe ApplicationHelper, type: :helper do
  let!(:user) { create(:user) }
  let!(:organization) { create(:organization, user_id: user.id) }
  let!(:collection_resource) { create(:collection_resource) }
  
  describe '#valid_json?' do
    it 'check valid json' do
      expect(helper.valid_json?('')).to be_falsey
      expect(helper.valid_json?('{invalid_json_string}')).to be_falsey
      expect(helper.valid_json?('{"0":{"text":"header","url":"header","childrenNum":0}}')).to be_truthy
    end
  end
  describe '#iso_639_1_languages' do
    it 'return language hash' do
      expect(helper.iso_639_1_languages).to be_truthy
    end
  end
  describe '#random_number' do
    it 'return random string' do
      expect(helper.random_number).to be_truthy
    end
  end
  describe '#available_states' do
    it 'return available_states list' do
      expect(helper.available_states).to be_truthy
    end
  end
  describe '#resource_percent' do
    it 'return resource_percent value' do
      expect(helper.resource_percent(1, 1)).to be(100)
    end
    end
  describe '#resource_percent' do
    it 'return resource_percent value' do
      expect(helper.storage_percent(1, 1)).to be(0)
    end
  end

  describe '#stopwords' do
    it 'return stopwords' do
      expect(helper.stopwords).to be_a_kind_of(Array)
    end
  end
  describe '#count_em' do
    it 'return count_em value' do
      expect(helper.count_em('testing string', 'testing')).to be(1)
    end
  end

  describe '#active_class' do
    it 'return active_class value' do
      expect(helper.active_class('link_to_page')).to be_an_kind_of(String)
    end
  end

  describe '#active_class_multiple' do
    it 'return active_class_multiple ' do
      expect(helper.active_class_multiple(%i'array_1 array2')).to be_an_kind_of(String)
    end
  end
  describe '#present' do
    it 'return present(model, presenter_class = nil)' do
      helper.present(collection_resource, CollectionResourcePresenter)
    end
  end


  describe '#count_em' do
    it 'return count_em value' do
      expect(helper.count_em('testing string', 'testing')).to be(1)
    end
  end
  
  before do
    def helper.current_organization;
    end
  end
  describe '#organization_layout?' do
    it 'return true if a valid organization' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.organization_layout?).to be_falsey
    end
  end

  describe '#Application_helper?' do
    it 'return true if a valid time_to_duration value' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.time_to_duration(120)).to eq('00:02:00')
    end
  end

  describe '#organization_logo' do
    it 'return the main logo' do
      allow(helper).to receive(:current_organization).and_return(nil)
      expect(helper.organization_logo).to include('/main-logo.png')
    end
  end
  describe '#organization_logo' do
    it 'return the organization logo' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.organization_logo).to be_truthy
    end
  end
  describe '#cost_pay_as_you_go' do
    it 'return the cost per resource 0.15 dollar' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.cost_pay_as_you_go(1000)).to be(150.0)
    end
    it 'return the cost per resource 0.09 dollar' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.cost_pay_as_you_go(4500)).to be(405.0)
    end
    it 'return the cost per resource 0.04 dollar' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.cost_pay_as_you_go(17500)).to be(700.0)
    end
    it 'return the cost per resource 0.02 dollar' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.cost_pay_as_you_go(25000)).to be(500.0)
    end
    it 'return the cost per resource 0.01 dollar' do
      allow(helper).to receive(:current_organization).and_return(organization)
      expect(helper.cost_pay_as_you_go(50001)).to be(500.01)
    end
  end
end
