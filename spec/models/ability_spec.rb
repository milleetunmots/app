require 'rails_helper'

RSpec.describe Ability do
  describe "le droit d'incarner une accompagnante" do
    {
      'super_admin' => true,
      'contributor' => true,
      'reader' => false,
      'caller' => false,
      'animator' => false
    }.each do |role, allowed|
      it "est #{allowed ? 'accordé' : 'refusé'} à un #{role}" do
        user = FactoryBot.create(:admin_user, user_role: role)

        expect(described_class.new(user).can?(:impersonate, AdminUser)).to be(allowed)
      end
    end
  end
end
