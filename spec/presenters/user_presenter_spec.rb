require "rails_helper"

RSpec.describe UserPresenter, type: :Decorator do

  let!(:user) { create(:user) }

  describe '#User ' do
    context ' User Decorator ' do
      it 'has attribute full_name' do
        user.decorate.full_name
      end
    end
  end
end