require 'rails_helper'

# La classe parente lit les identifiants Google au chargement : valeur factice, l'API est simulée.
ENV['GOOGLE_CREADENTIALS_JSON'] ||= Base64.encode64('{}')

RSpec.describe Child::SendEvalMessageService do
  def sheet_rows(*children)
    children.map { |child| Array.new(21).tap { |row| row[1] = child.id.to_s and row[6] = 'Test' } }
  end

  def stub_sheet(rows)
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(double)
    allow_any_instance_of(Google::Apis::SheetsV4::SheetsService).to receive(:get_spreadsheet_values).and_return(double(values: rows))
  end

  def eval_bundle
    FactoryBot.create(:media_text_messages_bundle, name: "Fin d'accompagnement, étude eval", body1: 'Texte du trio eval {LIEN_ETUDE_EVAL}', body2: nil, body3: nil)
              .update_column(:key, 'eval_fin_accompagnement')
  end

  let(:group) { FactoryBot.create(:group) }
  let(:lea) { FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'stopped', should_contact_parent1: true) }
  let(:hugo) { FactoryBot.create(:child, first_name: 'Hugo', parent1: lea.parent1, group: group, group_status: 'stopped', should_contact_parent1: true) }

  it "envoie un message par enfant, chacun avec le lien eval et le prénom de l'enfant, puis pose le tag" do
    eval_bundle
    stub_sheet(sheet_rows(lea, hugo))
    [lea, hugo].each do |child|
      expect(ProgramAutomaticMessageService).to receive(:new).with(
        anything, anything, ["child.#{child.id}"], 'Texte du trio eval {LIEN_ETUDE_EVAL}', nil, nil, false, nil, nil, %w[active stopped disengaged],
        automatic_message_key: 'eval_fin_accompagnement',
        recipient_variables: { child.parent1_id => { 'LIEN_ETUDE_EVAL' => a_string_ending_with("/ef/#{child.security_token}"), 'PRENOM_ENFANT' => child.first_name } }
      ).and_call_original
    end

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect([lea.reload, hugo.reload].map(&:tag_list)).to all(include('lien_eval25_envoye'))
  end

  it "n'envoie rien, ne pose pas le tag et signale le trio introuvable" do
    stub_sheet(sheet_rows(lea))
    expect(ProgramAutomaticMessageService).not_to receive(:new)

    service = described_class.new.call

    expect(lea.reload.tag_list).not_to include('lien_eval25_envoye')
    expect(service.errors).to include("Trio introuvable : « Fin d'accompagnement, étude eval » (clé eval_fin_accompagnement), message non envoyé")
  end
end
