#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
require "rails_helper"

RSpec.describe UserDecorator, type: :Decorator do

  let!(:user) { create(:user) }

  describe '#User ' do
    context ' User Decorator ' do
      it 'has attribute full_name' do
        user.decorate.full_name
      end
    end
  end
end