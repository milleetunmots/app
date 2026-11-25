require 'rails_helper'
require 'rake'
require 'csv'

RSpec.describe 'rcs:template_ids' do
  before(:all) do
    Rake.application.rake_require('tasks/rcs_template_ids', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  def csv_file(rows)
    file = Tempfile.new(['rcs_template_ids', '.csv'])
    CSV.open(file.path, 'w') do |csv|
      csv << %w[bundle_id key bundle_name message_index rcs_media_id]
      rows.each { |row| csv << row }
    end
    file
  end

  describe 'rcs:export_template_ids' do
    let(:task) { Rake::Task['rcs:export_template_ids'] }

    before { task.reenable }

    it 'écrit un modèle texte par ligne, avec de quoi retrouver son trio' do
      automatic = FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', key: 'fin_programme', body2: nil, body3: nil, rcs_media1_id: 4521, rcs_text_template1: true)
      FactoryBot.create(:media_text_messages_bundle, key: 'avec_carte', rcs_media1_id: 3310, rcs_text_template1: false)
      file = Tempfile.new(['export', '.csv'])

      expect { task.invoke(file.path) }.to output(/1 template id\(s\) exported/).to_stdout

      expect(CSV.read(file.path, headers: true).map(&:to_h)).to eq(
        [{ 'bundle_id' => automatic.id.to_s, 'key' => 'fin_programme', 'bundle_name' => 'Fin du programme', 'message_index' => '1', 'rcs_media_id' => '4521' }]
      )
    end
  end

  describe 'rcs:import_template_ids' do
    let(:task) { Rake::Task['rcs:import_template_ids'] }

    before { task.reenable }

    it "pose l'identifiant sur le trio de module retrouvé par son id et son nom" do
      bundle = FactoryBot.create(:media_text_messages_bundle, name: 'ModuleLecture-niveau1-semaine1/5', body2: nil, body3: nil)
      file = csv_file([[bundle.id, nil, 'ModuleLecture-niveau1-semaine1/5', 1, 1_239_600]])

      expect { task.invoke(file.path) }.to output(/Imported: 1.*Skipped: 0/m).to_stdout

      expect(bundle.reload).to have_attributes(rcs_media1_id: 1_239_600, rcs_text_template1: true)
    end

    it 'retrouve un trio automatique par sa clé, même si son id diffère' do
      bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', key: 'fin_programme', body2: nil, body3: nil)
      file = csv_file([[bundle.id + 1000, 'fin_programme', 'Fin du programme', 1, 1_239_601]])

      expect { task.invoke(file.path) }.to output(/Imported: 1/).to_stdout

      expect(bundle.reload).to have_attributes(rcs_media1_id: 1_239_601, rcs_text_template1: true)
    end

    it "ne remplace pas le modèle d'un message qui en a déjà un" do
      bundle = FactoryBot.create(:media_text_messages_bundle, body2: nil, body3: nil, rcs_media1_id: 4521, rcs_text_template1: true)
      file = csv_file([[bundle.id, nil, bundle.name, 1, 1_239_602]])

      expect { task.invoke(file.path) }.to output(/already has template 4521.*Imported: 0.*Skipped: 1/m).to_stdout

      expect(bundle.reload.rcs_media1_id).to eq(4521)
    end

    it "ignore une ligne dont le trio a changé de nom ou n'existe plus" do
      renamed = FactoryBot.create(:media_text_messages_bundle, name: 'Nouveau nom', body2: nil, body3: nil)
      file = csv_file([[renamed.id, nil, 'Ancien nom', 1, 1_239_603], [renamed.id + 1000, nil, 'Disparu', 1, 1_239_604]])

      expect { task.invoke(file.path) }.to output(/bundle not found.*bundle not found.*Imported: 0.*Skipped: 2/m).to_stdout

      expect(renamed.reload.rcs_media1_id).to be_nil
    end

    it 'ignore un message devenu vide ou qui a désormais une image' do
      emptied = FactoryBot.create(:media_text_messages_bundle, body2: '', body3: nil)
      with_image = FactoryBot.create(:media_text_messages_bundle, body2: nil, body3: nil, image1_id: FactoryBot.create(:media_image).id)
      file = csv_file([[emptied.id, nil, emptied.name, 2, 1_239_605], [with_image.id, nil, with_image.name, 1, 1_239_606]])

      expect { task.invoke(file.path) }.to output(/message is empty.*message has an image.*Imported: 0.*Skipped: 2/m).to_stdout

      expect(emptied.reload.rcs_media2_id).to be_nil
      expect(with_image.reload.rcs_media1_id).to be_nil
    end
  end
end
