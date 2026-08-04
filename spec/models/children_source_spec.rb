require "rails_helper"

RSpec.describe ChildrenSource, type: :model do

  describe "professional_email validation" do
    it "is valid when blank" do
      children_source = ChildrenSource.new(professional_email: nil)
      children_source.valid?
      expect(children_source.errors[:professional_email]).to be_empty
    end

    it "is valid with a well formatted email" do
      children_source = ChildrenSource.new(professional_email: "pro@pmi75.fr")
      children_source.valid?
      expect(children_source.errors[:professional_email]).to be_empty
    end

    it "is invalid with a badly formatted email" do
      children_source = ChildrenSource.new(professional_email: "not-an-email")
      children_source.valid?
      expect(children_source.errors[:professional_email]).not_to be_empty
    end
  end
end