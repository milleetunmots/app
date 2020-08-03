require 'rails_helper'

RSpec.describe Media::Form, type: :model do

  before(:each) do
    @form = FactoryBot.build(:media_form)
  end

  context 'is valid' do
    it 'if minimal attributes are present' do
      expect(@form).to be_valid
    end
  end

  context 'is not valid' do
    it 'if no URL is given' do
      @form.url = nil
      expect(@form).to_not be_valid
    end
  end

end
