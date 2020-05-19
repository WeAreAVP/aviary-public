require "rails_helper"

RSpec.describe FileIndex, type: :model do
  let(:file_index_invalid) { build :file_index, attributes_for(:file_index, :invalid) }
  let(:file_index_invalid_webvtt) { build :file_index, attributes_for(:file_index, :invalid_webvtt) }
  let(:file_index_webvtt_missing) { build :file_index, attributes_for(:file_index, :use_webvtt_missing_time) }
  let(:file_index_ohms_missing) { build :file_index, attributes_for(:file_index, :use_ohms_missing) }
  context 'properties' do
    subject { create :file_index }
    it 'should include attributes' do
      expect(subject).to have_attribute(:title)
      expect(subject).to have_attribute(:language)
      expect(subject).to have_attribute(:is_public)
      expect(subject).to have_attribute(:sort_order)
      expect(subject).to have_attribute(:sort_order)
    end
  end
  it 'should pass the file xml validation for invalid xml because of relaxing rules' do
    file_index_invalid.valid?
    expect(file_index_invalid.errors[:associated_file].size).to eq(0)
    expect(file_index_invalid.errors[:title].size).to eq(1)
  end
  it 'should fail the file webvtt validation' do
    file_index_invalid_webvtt.valid?
    expect(file_index_invalid_webvtt.errors[:associated_file].size).to eq(1)
  end
  it 'should fail the file webvtt validation because of missing title' do
    file_index_webvtt_missing.valid?
    expect(file_index_webvtt_missing.errors[:associated_file].size).to eq(1)
  end
  it 'should fail the file ohms validation because of missing title' do
    file_index_ohms_missing.valid?
    expect(file_index_ohms_missing.errors[:associated_file].size).to eq(1)
  end

end
