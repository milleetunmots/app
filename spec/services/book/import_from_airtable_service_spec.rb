require 'rails_helper'

RSpec.describe Book::ImportFromAirtableService do
  # convention du projet : on stubbe les classes Airtables::*, jamais le HTTP.
  # Seuls les téléchargements d'images, faits par le service lui-même, sont
  # stubbés au niveau HTTP.
  let(:cover_url) { 'https://airtable.test/couverture.jpg' }
  let(:image_body) { File.binread(Dir.glob('db/seed/img/**/*.jpg').first) }
  # Taille franchement différente : c'est ce qui distingue deux photos de même nom.
  let(:other_image_body) { File.binread(Dir.glob('db/seed/img/**/*.jpg')[1]) }
  let!(:book) { FactoryBot.create(:book, ean: '1234567890', title: 'Petit ours brun') }

  # Les modules sont appariés sur l'airtable_id rapatrié en amont par
  # SupportModule::SyncAirtableIdsService, pas sur le titre
  let!(:support_module) do
    FactoryBot.create(:support_module,
                      name: 'Chanter avec mon enfant',
                      age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN],
                      airtable_id: 'recAAA')
  end

  before do
    stub_request(:get, cover_url).to_return(status: 200, body: image_body)
  end

  def attached_filenames(record)
    record.reload.interior_photos.map { |photo| photo.blob.filename.to_s }
  end

  def photo_url(filename)
    "https://airtable.test/#{filename}"
  end

  # Pièce jointe dont le téléchargement échoue.
  def failing_airtable_photo(filename, status: 404)
    stub_request(:get, photo_url(filename)).to_return(status: status)
    { 'filename' => filename, 'url' => photo_url(filename), 'type' => 'image/jpeg', 'size' => 1234 }
  end

  # Façonne une pièce jointe Airtable et stubbe son téléchargement.
  def airtable_photo(filename, body: image_body)
    stub_request(:get, photo_url(filename)).to_return(status: 200, body: body)
    { 'filename' => filename, 'url' => photo_url(filename), 'type' => 'image/jpeg', 'size' => body.bytesize }
  end

  # interior_photos: :absent => la clé n'existe pas du tout côté Airtable.
  def airtable_record(ean:, title:, modules: [], interior_photos: :absent, cover: :default)
    record = {
      'EAN' => ean,
      'Titre du livre' => title,
      'Modules' => modules
    }
    if cover == :default
      record['Photo de la couverture'] = [{ 'filename' => 'couverture.jpg', 'url' => cover_url, 'type' => 'image/jpeg' }]
    elsif cover != :absent
      record['Photo de la couverture'] = cover
    end
    record['Photos intérieures'] = interior_photos unless interior_photos == :absent
    record
  end

  def stub_airtable_records(records)
    allow(Airtables::Book).to receive(:all).and_return(records)
  end

  def stub_airtable(module_record_ids, interior_photos: :absent, ean: book.ean, title: book.title, cover: :default)
    stub_airtable_records(
      [airtable_record(ean: ean, title: title, modules: module_record_ids,
                       interior_photos: interior_photos, cover: cover)]
    )
  end

  it 'rattache au livre les modules appariés sur Airtable' do
    stub_airtable(['recAAA'])

    service = described_class.new.call

    expect(service.errors[:support_modules]).to be_empty
    expect(book.reload.support_module_ids).to eq([support_module.id])
  end

  it "n'interroge pas Airtable module par module" do
    stub_airtable(['recAAA'])
    allow(Airtables::Module).to receive(:find)

    described_class.new.call

    expect(Airtables::Module).not_to have_received(:find)
  end

  it "signale par un lien Airtable les modules introuvables en base" do
    stub_airtable(['recBBB'])

    service = described_class.new.call

    expect(service.errors[:support_modules])
      .to contain_exactly("Module Airtable introuvable : #{Airtables::Module.record_url('recBBB')}")
    expect(book.reload.support_module_ids).to be_empty
  end

  it "détache les modules d'un livre absent d'Airtable" do
    other_book = FactoryBot.create(:book, ean: '9999999999')
    other_book.support_modules << support_module
    stub_airtable([])

    described_class.new.call

    expect(other_book.reload.support_module_ids).to be_empty
  end

  describe 'photos intérieures' do
    it 'télécharge et rattache les photos intérieures du livre' do
      stub_airtable(['recAAA'],
                    interior_photos: [airtable_photo('interieur-1.jpg'), airtable_photo('interieur-2.jpg')])

      service = described_class.new.call

      expect(service.errors[:interior_photos]).to be_empty
      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg', 'interieur-2.jpg')
    end

    it "conserve le nom de fichier et le content type d'origine" do
      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg')])

      described_class.new.call

      blob = book.reload.interior_photos.first.blob
      expect(blob.filename.to_s).to eq('interieur-1.jpg')
      expect(blob.content_type).to eq('image/jpeg')
    end

    # Le champ n'est pas renseigné pour tous les livres : son absence ne doit
    # ni lever d'erreur, ni interrompre l'import.
    it "n'attache rien quand le champ est absent d'Airtable" do
      stub_airtable(['recAAA'])

      service = described_class.new.call

      expect(service.errors[:interior_photos]).to be_empty
      expect(attached_filenames(book)).to be_empty
    end

    it "n'attache rien quand le champ est vide" do
      stub_airtable(['recAAA'], interior_photos: [])

      service = described_class.new.call

      expect(service.errors[:interior_photos]).to be_empty
      expect(attached_filenames(book)).to be_empty
    end

    # Un livre créé par l'import lui-même doit être persisté avant qu'on
    # puisse lui attacher des fichiers.
    it "rattache les photos à un livre créé pendant l'import" do
      stub_airtable(['recAAA'],
                    ean: '5550001111',
                    title: 'Nouveau livre',
                    interior_photos: [airtable_photo('interieur-1.jpg')])

      described_class.new.call

      created = Book.find_by(ean: '5550001111')
      expect(created).to be_present
      expect(attached_filenames(created)).to contain_exactly('interieur-1.jpg')
    end

    it 'ne laisse aucun fichier temporaire derrière lui' do
      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg')])

      described_class.new.call

      expect(File).not_to exist(Rails.root.join('tmp/images/interieur-1.jpg'))
      expect(File).not_to exist(Rails.root.join('tmp/images/couverture.jpg'))
    end
  end

  describe 'resynchronisation des photos intérieures' do
    it "supprime de la base une photo retirée d'Airtable" do
      stub_airtable(['recAAA'],
                    interior_photos: [airtable_photo('interieur-1.jpg'), airtable_photo('interieur-2.jpg')])
      described_class.new.call
      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg', 'interieur-2.jpg')

      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg')])
      described_class.new.call

      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg')
    end

    it 'télécharge une photo ajoutée dans Airtable' do
      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg')])
      described_class.new.call

      stub_airtable(['recAAA'],
                    interior_photos: [airtable_photo('interieur-1.jpg'), airtable_photo('interieur-2.jpg')])
      described_class.new.call

      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg', 'interieur-2.jpg')
    end

    # Garde-fou : sans clé d'identité fiable, le job nocturne retéléchargerait
    # toutes les photos de tous les livres à chaque passage.
    it "ne retélécharge rien lors d'un second passage identique" do
      stub_airtable(['recAAA'],
                    interior_photos: [airtable_photo('interieur-1.jpg'), airtable_photo('interieur-2.jpg')])

      described_class.new.call
      described_class.new.call

      expect(a_request(:get, photo_url('interieur-1.jpg'))).to have_been_made.once
      expect(a_request(:get, photo_url('interieur-2.jpg'))).to have_been_made.once
      expect(book.reload.interior_photos.count).to eq(2)
    end

    it 'retélécharge une photo de même nom mais de taille différente' do
      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg')])
      described_class.new.call
      expect(book.reload.interior_photos.first.blob.byte_size).to eq(image_body.bytesize)

      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg', body: other_image_body)])
      described_class.new.call

      expect(book.reload.interior_photos.count).to eq(1)
      expect(book.reload.interior_photos.first.blob.byte_size).to eq(other_image_body.bytesize)
    end

    # Un import interrompu puis relancé peut laisser deux fois la même photo.
    # La clé d'identité ne distinguant pas les exemplaires, il faut purger les
    # surnuméraires, sans quoi le doublon reste en base indéfiniment.
    it 'purge les exemplaires en double laissés par un import interrompu' do
      stub_airtable(['recAAA'], interior_photos: [airtable_photo('interieur-1.jpg')])
      described_class.new.call

      book.interior_photos.attach(
        io: StringIO.new(image_body), filename: 'interieur-1.jpg', content_type: 'image/jpeg'
      )
      expect(book.reload.interior_photos.count).to eq(2)

      described_class.new.call

      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg')
    end

    it "ne touche pas aux photos d'un autre livre" do
      other_book = FactoryBot.create(:book, ean: '9999999999', title: 'Autre livre')
      stub_airtable_records(
        [
          airtable_record(ean: book.ean, title: book.title,
                          interior_photos: [airtable_photo('interieur-1.jpg')]),
          airtable_record(ean: other_book.ean, title: other_book.title,
                          interior_photos: [airtable_photo('interieur-2.jpg')])
        ]
      )

      described_class.new.call

      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg')
      expect(attached_filenames(other_book)).to contain_exactly('interieur-2.jpg')
    end
  end

  describe 'robustesse des téléchargements' do
    # Une photo en échec ne doit compromettre ni les autres photos du livre,
    # ni les livres suivants : l'import nocturne irait sinon droit dans le mur
    # au premier lien Airtable expiré.
    it "consigne l'erreur et poursuit quand une photo est introuvable" do
      stub_airtable(['recAAA'],
                    interior_photos: [failing_airtable_photo('absente.jpg'), airtable_photo('interieur-1.jpg')])

      service = described_class.new.call

      expect(service.errors[:interior_photos].size).to eq(1)
      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg')
    end

    it "identifie le livre et le fichier dans le message d'erreur" do
      stub_airtable(['recAAA'], interior_photos: [failing_airtable_photo('absente.jpg')])

      service = described_class.new.call

      expect(service.errors[:interior_photos].first).to include('absente.jpg').and include(book.ean)
    end

    it 'traite les livres suivants malgré une photo en échec' do
      other_book = FactoryBot.create(:book, ean: '9999999999', title: 'Autre livre')
      stub_airtable_records(
        [
          airtable_record(ean: book.ean, title: book.title,
                          interior_photos: [failing_airtable_photo('absente.jpg')]),
          airtable_record(ean: other_book.ean, title: other_book.title,
                          interior_photos: [airtable_photo('interieur-2.jpg')])
        ]
      )

      described_class.new.call

      expect(attached_filenames(other_book)).to contain_exactly('interieur-2.jpg')
    end

    it 'ne laisse aucun fichier temporaire après un échec' do
      stub_airtable(['recAAA'], interior_photos: [failing_airtable_photo('absente.jpg')])

      described_class.new.call

      expect(File).not_to exist(Rails.root.join('tmp/images/absente.jpg'))
    end
  end

  describe 'défenses aux frontières' do
    # C1 — le nom de fichier vient d'une API externe : il ne doit jamais
    # pouvoir désigner un chemin hors de tmp/images.
    it 'ne sort pas de tmp/images quand Airtable renvoie un chemin relatif' do
      stub_request(:get, photo_url('evil')).to_return(status: 200, body: image_body)
      evil = { 'filename' => '../../../evil_payload.jpg', 'url' => photo_url('evil'),
               'type' => 'image/jpeg', 'size' => image_body.bytesize }
      stub_airtable(['recAAA'], interior_photos: [evil])

      described_class.new.call

      # Le fichier temporaire étant effacé en fin de traitement, constater son
      # absence ne prouverait rien : c'est le chemin calculé qu'on vérifie.
      resolved = described_class.allocate.send(:tmp_path, '../../../evil_payload.jpg')
      expect(resolved.to_s).to start_with(Rails.root.join('tmp/images').to_s)
      expect(book.reload.interior_photos.count).to eq(1)
    end

    # R1 — attach ne lève pas quand la validation échoue, il renvoie false.
    # Sans contrôle du retour, la photo disparaît sans la moindre trace.
    it 'consigne une erreur quand le type de contenu est refusé' do
      stub_request(:get, photo_url('doc.pdf')).to_return(status: 200, body: '%PDF-1.4 faux')
      pdf = { 'filename' => 'doc.pdf', 'url' => photo_url('doc.pdf'),
              'type' => 'application/pdf', 'size' => 13 }
      stub_airtable(['recAAA'], interior_photos: [pdf])

      service = described_class.new.call

      expect(service.errors[:interior_photos].size).to eq(1)
      expect(service.errors[:interior_photos].first).to include('doc.pdf')
      expect(book.reload.interior_photos).to be_empty
    end

    # R2 — un délai dépassé est bien plus probable qu'un refus de connexion
    # sur une URL S3 signée ; il ne doit pas avorter l'import.
    it 'consigne une erreur et poursuit quand le téléchargement expire' do
      stub_request(:get, photo_url('lente.jpg')).to_timeout
      slow = { 'filename' => 'lente.jpg', 'url' => photo_url('lente.jpg'),
               'type' => 'image/jpeg', 'size' => 10 }
      stub_airtable(['recAAA'], interior_photos: [slow, airtable_photo('interieur-1.jpg')])

      service = described_class.new.call

      expect(service.errors[:interior_photos].size).to eq(1)
      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg')
    end

    it "consigne une erreur quand l'URL Airtable est malformée" do
      broken = { 'filename' => 'cassee.jpg', 'url' => 'http://exa mple.test/cassee.jpg',
                 'type' => 'image/jpeg', 'size' => 10 }
      stub_airtable(['recAAA'], interior_photos: [broken])

      service = described_class.new.call

      expect(service.errors[:interior_photos].size).to eq(1)
      expect(book.reload.interior_photos).to be_empty
    end
  end

  describe 'confiance accordée à Airtable' do
    # Point 1 — une couverture en échec ne doit pas emporter tout l'import.
    it "consigne l'erreur et poursuit quand la couverture est introuvable" do
      stub_request(:get, cover_url).to_return(status: 404)
      other_book = FactoryBot.create(:book, ean: '9999999999', title: 'Autre livre')
      stub_airtable_records(
        [
          airtable_record(ean: book.ean, title: book.title),
          airtable_record(ean: other_book.ean, title: other_book.title,
                          interior_photos: [airtable_photo('interieur-2.jpg')])
        ]
      )

      service = described_class.new.call

      expect(service.errors[:cover].size).to eq(2)
      expect(service.errors[:cover].first).to include(book.ean)
      expect(attached_filenames(other_book)).to contain_exactly('interieur-2.jpg')
    end

    it "n'échoue pas quand le livre n'a aucune couverture dans Airtable" do
      stub_airtable(['recAAA'], cover: :absent,
                                interior_photos: [airtable_photo('interieur-1.jpg')])

      service = described_class.new.call

      expect(service.errors[:cover]).to be_empty
      expect(attached_filenames(book)).to contain_exactly('interieur-1.jpg')
    end

    # Point 2 — ActiveStorage réécrit certains noms au stockage ; la clé doit
    # comparer ce qui est comparable, sans quoi la photo revient chaque nuit.
    it 'ne retélécharge pas une photo dont le nom est réécrit au stockage' do
      stub_request(:get, photo_url('weird')).to_return(status: 200, body: image_body)
      weird = { 'filename' => '../../interieur.jpg', 'url' => photo_url('weird'),
                'type' => 'image/jpeg', 'size' => image_body.bytesize }
      stub_airtable(['recAAA'], interior_photos: [weird])

      described_class.new.call
      described_class.new.call

      expect(a_request(:get, photo_url('weird'))).to have_been_made.once
      expect(book.reload.interior_photos.count).to eq(1)
    end

    # Point 3 — le vrai risque : la taille annoncée ne correspond pas aux
    # octets servis. Sans garde, tout est retéléchargé chaque nuit en silence.
    it 'ne retélécharge pas quand la taille annoncée diffère des octets servis' do
      stub_request(:get, photo_url('interieur-1.jpg')).to_return(status: 200, body: image_body)
      mismatched = { 'filename' => 'interieur-1.jpg', 'url' => photo_url('interieur-1.jpg'),
                     'type' => 'image/jpeg', 'size' => 999_999 }
      stub_airtable(['recAAA'], interior_photos: [mismatched])

      described_class.new.call
      described_class.new.call

      expect(a_request(:get, photo_url('interieur-1.jpg'))).to have_been_made.once
      expect(book.reload.interior_photos.count).to eq(1)
    end
  end
end
