require 'rails_helper'

# Les combinaisons de rôles sont couvertes par spec/models/ability_spec.rb (opérateur)
# et spec/models/admin_user_spec.rb#impersonable? (cible) : on garde ici un cas par issue.
RSpec.describe AdminUser::StartImpersonationService do
  def start(operator:, target:)
    described_class.new(operator: operator, target: target).call
  end

  describe '#call' do
    it 'ouvre une ligne de journal quand un opérateur autorisé incarne une accompagnante' do
      operator = FactoryBot.create(:admin_user, user_role: 'contributor')
      target = FactoryBot.create(:admin_user, user_role: 'caller')

      service = nil
      expect { service = start(operator: operator, target: target) }
        .to change(AdminUserImpersonation, :count).by(1)

      expect(service.errors).to be_empty
      expect(service.impersonation).to have_attributes(
        operator: operator, target: target, ended_at: nil
      )
      expect(service.impersonation.started_at).to be_within(5.seconds).of(Time.current)
    end

    it "refuse un opérateur qui n'a pas le droit d'incarner sans rien enregistrer" do
      operator = FactoryBot.create(:admin_user, user_role: 'reader')
      target = FactoryBot.create(:admin_user, user_role: 'caller')

      service = nil
      expect { service = start(operator: operator, target: target) }
        .not_to change(AdminUserImpersonation, :count)

      expect(service.impersonation).to be_nil
      expect(service.errors).to eq(
        [{ message: 'Action non autorisée', context: { operator_id: operator.id, target_id: target.id } }]
      )
    end

    it 'refuse une cible non incarnable sans rien enregistrer' do
      operator = FactoryBot.create(:admin_user, user_role: 'contributor')
      target = FactoryBot.create(:admin_user, user_role: 'caller', is_disabled: true)

      service = nil
      expect { service = start(operator: operator, target: target) }
        .not_to change(AdminUserImpersonation, :count)

      expect(service.impersonation).to be_nil
      expect(service.errors).to eq(
        [{ message: 'Impossible de se connecter en tant que ce compte', context: { operator_id: operator.id, target_id: target.id } }]
      )
    end

    it 'retourne le service lui-même, y compris en échec' do
      operator = FactoryBot.create(:admin_user, user_role: 'reader')
      target = FactoryBot.create(:admin_user, user_role: 'caller')
      service = described_class.new(operator: operator, target: target)

      expect(service.call).to equal(service)
    end
  end
end
