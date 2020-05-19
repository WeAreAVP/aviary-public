require "rails_helper"

RSpec.describe FileIndexPointPresenter, type: :Presenter do
  let(:file_index_point) { create :file_index_point }
  let(:template) { ActionController::Base.new.view_context }
  let(:presenter) { FileIndexPointPresenter.new(file_index_point, template) }
  describe '#FileIndexPointPresenter ' do
    context 'Check Presenter Methods' do
      it 'should provide time in format' do
        expect(presenter.display_time).to eq('00:00:06')
      end
      it 'should provide formatted partial transcirpt' do
        expect(presenter.partial_transcript).to be_truthy
      end
      it 'should provide formatted subjects' do
        expect(presenter.display_subjects).to be_truthy
      end
      it 'should provide formatted keywords' do
        expect(presenter.display_keywords).to be_truthy
      end
      it 'should provide formatted gps link' do
        expect(presenter.gps).to be_truthy
      end
      it 'should provide formatted hyperlink' do
        expect(presenter.display_hyperlink).to be_truthy
      end
      it 'should provide formatted gps link without description' do
        gps = JSON.parse(file_index_point.gps_points)
        gps[0]['description'] = ''
        file_index_point.gps_points = gps.to_json
        expect(presenter.gps).to include('GPS Location')
      end
    end
  end
end