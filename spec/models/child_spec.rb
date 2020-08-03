require 'rails_helper'

RSpec.describe Child, type: :model do

  before(:each) do
    @child = FactoryBot.build(:child)
  end

  context 'is valid' do
    it 'if minimal attributes are present' do
      expect(@child).to be_valid
    end
  end

end
