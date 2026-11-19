require 'rails_helper'

RSpec.describe ChildSupport::SaveCallGoalsService do
  let!(:child) { FactoryBot.create(:child) }
  let(:child_support) { child.child_support }
  let(:message) { "Voici votre petite mission :\r\nLire une histoire\r\nQuand vous aurez essayé" }

  describe '.template?' do
    it 'reconnaît les modèles de petite mission' do
      expect(described_class.template?('call3_goals_observing')).to be(true)
    end

    it 'écarte les autres modèles' do
      expect(described_class.template?('scheduled_call_reminder')).to be(false)
      expect(described_class.template?('Aucun')).to be(false)
      expect(described_class.template?(nil)).to be(false)
    end
  end

  describe '#call' do
    goals_columns = %w[call0_goals_sms call1_goals_sms call2_goals_sms call3_goals_sms]

    {
      'call0_goals' => 'call0_goals_sms',
      'call1_goals' => 'call1_goals_sms',
      'call2_goals' => 'call2_goals_sms',
      'call3_goals' => 'call3_goals_sms',
      'call3_goals_observing' => 'call3_goals_sms',
      'call3_goals_speaking' => 'call3_goals_sms'
    }.each do |template, column|
      context "avec le modèle #{template}" do
        it "écrit le message dans #{column}, et seulement là" do
          service = described_class.new(child_support: child_support, template: template, message: message).call

          expect(service.errors).to be_empty
          expect(service.skipped?).to be(false)
          child_support.reload
          expect(child_support.send(column)).to eq(message)
          (goals_columns - [column]).each do |other_column|
            expect(child_support.send(other_column)).to be_blank
          end
        end
      end
    end

    context "avec le modèle de l'appel 0" do
      it 'retient la mission pour le rappel' do
        described_class.new(child_support: child_support, template: 'call0_goals', message: message, call_goal: 'Chanter une comptine au bain').call

        expect(child_support.reload.call0_goal_sent).to eq('Chanter une comptine au bain')
      end
    end

    context "avec le modèle d'un autre appel" do
      it 'ne touche pas à la mission retenue pour le rappel de l’appel 0' do
        child_support.update_column(:call0_goal_sent, 'Mission de l’appel 0')

        described_class.new(child_support: child_support, template: 'call1_goals', message: message, call_goal: 'Autre mission').call

        expect(child_support.reload.call0_goal_sent).to eq('Mission de l’appel 0')
      end
    end

    context 'quand la case contient déjà une petite mission' do
      before { child_support.update_column(:call1_goals_sms, 'PM reformulée') }

      it 'la remplace par défaut' do
        service = described_class.new(child_support: child_support, template: 'call1_goals', message: message).call

        expect(service.skipped?).to be(false)
        expect(child_support.reload.call1_goals_sms).to eq(message)
      end

      it 'la laisse en place sans écrasement' do
        service = described_class.new(child_support: child_support, template: 'call1_goals', message: message, overwrite: false).call

        expect(service.errors).to be_empty
        expect(service.skipped?).to be(true)
        expect(child_support.reload.call1_goals_sms).to eq('PM reformulée')
      end

      it 'la laisse en place sans écrasement même quand elle est identique' do
        child_support.update_column(:call1_goals_sms, message)

        service = described_class.new(child_support: child_support, template: 'call1_goals', message: message, overwrite: false).call

        expect(service.skipped?).to be(true)
        expect(child_support.reload.call1_goals_sms).to eq(message)
      end

      it "ne retient pas la mission de l'appel 0 quand la case n'est pas écrasée" do
        child_support.update_columns(call0_goals_sms: 'PM déjà là', call0_goal_sent: 'Mission déjà là')

        described_class.new(child_support: child_support, template: 'call0_goals', message: message, call_goal: 'Nouvelle mission', overwrite: false).call

        expect(child_support.reload.call0_goal_sent).to eq('Mission déjà là')
      end
    end

    context 'quand la case est vide et sans écrasement' do
      it 'écrit la petite mission' do
        service = described_class.new(child_support: child_support, template: 'call2_goals', message: message, overwrite: false).call

        expect(service.skipped?).to be(false)
        expect(child_support.reload.call2_goals_sms).to eq(message)
      end
    end

    context 'sans fiche de suivi' do
      it 'renvoie une erreur sans rien écrire' do
        service = described_class.new(child_support: nil, template: 'call1_goals', message: message).call

        expect(service.errors).to eq([{ message: 'Aucune fiche de suivi pour enregistrer la petite mission', context: { template: 'call1_goals' } }])
      end
    end

    context 'avec un modèle qui n’est pas une petite mission' do
      it 'renvoie une erreur sans rien écrire' do
        service = described_class.new(child_support: child_support, template: 'scheduled_call_reminder', message: message).call

        expect(service.errors).to eq([{ message: 'Modèle de petite mission inconnu : scheduled_call_reminder', context: { template: 'scheduled_call_reminder' } }])
        expect(child_support.reload.attributes.values_at('call0_goals_sms', 'call1_goals_sms', 'call2_goals_sms', 'call3_goals_sms')).to all(be_blank)
      end
    end
  end
end
