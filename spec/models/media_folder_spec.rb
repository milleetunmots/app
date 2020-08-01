require 'rails_helper'

RSpec.describe MediaFolder, type: :model do

  before(:each) do
    @media_folder = FactoryBot.build(
      :media_folder
    )
  end

  context 'is valid' do
    it 'if a name is present' do
      expect(@media_folder).to be_valid
    end
  end

  context 'is not valid' do
    it 'if no name is given' do
      @media_folder.name = nil
      expect(@media_folder).to_not be_valid
    end
    it 'if it is its own parent' do
      @media_folder.save!
      @media_folder.parent = @media_folder
      expect(@media_folder).to_not be_valid
    end
  end

end
