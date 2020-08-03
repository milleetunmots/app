# == Schema Information
#
# Table name: media
#
#  id           :bigint           not null, primary key
#  body1        :text
#  body2        :text
#  body3        :text
#  discarded_at :datetime
#  name         :string
#  type         :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  folder_id    :bigint
#  image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#
# Indexes
#
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_folder_id     (folder_id)
#  index_media_on_image1_id     (image1_id)
#  index_media_on_image2_id     (image2_id)
#  index_media_on_image3_id     (image3_id)
#  index_media_on_type          (type)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => media_folders.id)
#  fk_rails_...  (image1_id => media.id)
#  fk_rails_...  (image2_id => media.id)
#  fk_rails_...  (image3_id => media.id)
#


require 'rails_helper'

RSpec.describe Media::Image, type: :model do

  before(:each) do
    @image = FactoryBot.build(
      :media_image
    )
  end

  context 'is valid' do
    it 'if minimal attributes are present' do
      expect(@image).to be_valid
    end
  end

  context 'is not valid' do
    it 'if no file is given' do
      @image.file = nil
      expect(@image).to_not be_valid
    end
    it 'if file is of wrong type' do
      @image.file.attach(
        io: File.open('db/seed/pdf/birdy.pdf'),
        filename: 'Birdy',
        content_type: 'application/pdf'
      )
      expect(@image).to_not be_valid
    end
  end

end
