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
  subject { FactoryBot.create(:media_folder) }

  describe "#name" do
    it "is required" do
      subject.name = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#parent" do
    it "is another folder or doesn't exist" do
      subject.parent = subject

      expect(subject).to_not be_valid
    end
  end

  describe ".without_parent" do
    let(:parent) { FactoryBot.create(:media_folder) }
    let(:second_folder) { FactoryBot.create(:media_folder, parent: parent) }

    context "returns" do
      it "media folders without parent" do
        expect(MediaFolder.without_parent).to match_array [parent, subject]
        expect(MediaFolder.all).to match_array [parent, subject, second_folder]
      end
    end
  end
end
