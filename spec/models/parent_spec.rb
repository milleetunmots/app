require 'rails_helper'

RSpec.describe Parent, type: :model do

  before(:each) do
    @parent = FactoryBot.build(:parent)
  end

  context 'is valid' do
    it 'if minimal attributes are present' do
      expect(@parent).to be_valid
    end
  end

end
