# == Schema Information
#
# Table name: admin_user_impersonations
#
#  id          :bigint           not null, primary key
#  ended_at    :datetime
#  started_at  :datetime         not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  operator_id :bigint           not null
#  target_id   :bigint           not null
#
# Indexes
#
#  index_admin_user_impersonations_on_operator_id  (operator_id)
#  index_admin_user_impersonations_on_target_id    (target_id)
#
# Foreign Keys
#
#  fk_rails_...  (operator_id => admin_users.id)
#  fk_rails_...  (target_id => admin_users.id)
#
require 'rails_helper'

RSpec.describe AdminUserImpersonation do
  let(:operator) { FactoryBot.create(:admin_user, user_role: 'contributor') }
  let(:target) { FactoryBot.create(:admin_user, user_role: 'caller') }

  describe 'validations' do
    it 'est valide avec un opérateur, une cible et un début' do
      impersonation = FactoryBot.build(:admin_user_impersonation, operator: operator, target: target)

      expect(impersonation).to be_valid
    end

    it 'est invalide sans opérateur' do
      impersonation = FactoryBot.build(:admin_user_impersonation, operator: nil, target: target)

      expect(impersonation).not_to be_valid
    end

    it 'est invalide sans cible' do
      impersonation = FactoryBot.build(:admin_user_impersonation, operator: operator, target: nil)

      expect(impersonation).not_to be_valid
    end

    it 'est invalide sans début' do
      impersonation = FactoryBot.build(:admin_user_impersonation, operator: operator, target: target, started_at: nil)

      expect(impersonation).not_to be_valid
    end
  end

  describe 'associations' do
    it "retrouve l'opérateur et la cible" do
      impersonation = FactoryBot.create(:admin_user_impersonation, operator: operator, target: target)

      expect(impersonation.reload.operator).to eq(operator)
      expect(impersonation.target).to eq(target)
    end
  end

  describe '.ongoing' do
    it 'ne retourne que les connexions en tant que sans fin' do
      ongoing = FactoryBot.create(:admin_user_impersonation, operator: operator, target: target)
      FactoryBot.create(:admin_user_impersonation, operator: operator, target: target, ended_at: 1.hour.ago)

      expect(described_class.ongoing).to contain_exactly(ongoing)
    end
  end

  describe '#finish!' do
    let(:impersonation) { FactoryBot.create(:admin_user_impersonation, operator: operator, target: target) }

    it 'renseigne la fin avec la date courante' do
      freeze_time do
        impersonation.finish!

        expect(impersonation.reload.ended_at).to eq(Time.current)
      end
    end

    it 'ne change pas la fin au second appel' do
      first_end = 2.hours.ago.change(usec: 0)
      impersonation.update!(ended_at: first_end)

      impersonation.finish!

      expect(impersonation.reload.ended_at).to eq(first_end)
    end
  end
end
