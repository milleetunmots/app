# == Schema Information
#
# Table name: media_folders
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :bigint
#
# Indexes
#
#  index_media_folders_on_parent_id  (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => media_folders.id)
#

require "rails_helper"

RSpec.describe MediaFolder, type: :model do

  before(:each) do
    @media_folder1 = FactoryBot.create(:media_folder)
    @media_folder2 = FactoryBot.create(:media_folder, parent: @media_folder1)
  end

  describe "Validations" do
    context "succeed" do
      it "if a name is present" do
        expect(FactoryBot.build(:media_folder)).to be_valid
      end
    end

    context "fail" do
      it "if no name is given" do
        expect(FactoryBot.build(:media_folder, name: nil)).not_to be_valid
      end

      it "if it is its own parent" do
        @media_folder1.parent= @media_folder1
        expect(@media_folder1).to_not be_valid
      end
    end
  end

  describe "#without_parent" do
    context "returns" do
      it "media folders without parent" do
        expect(MediaFolder.without_parent).to match_array [@media_folder1]
        expect(MediaFolder.all).to match_array [@media_folder1, @media_folder2]
      end
    end
  end
end
