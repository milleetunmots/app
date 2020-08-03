require 'rails_helper'

RSpec.describe Media::Video, type: :model do

  before(:each) do
    @video = FactoryBot.build(:media_video)
  end

  context 'is valid' do
    it 'if minimal attributes are present' do
      expect(@video).to be_valid
    end
  end

  context 'is not valid' do
    it 'if no URL is given' do
      @video.url = nil
      expect(@video).to_not be_valid
    end
  end

end
