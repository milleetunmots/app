require 'rails_helper'

RSpec.describe BlockedPattern::AuditService do
  it 'compte les messages sortants qui matcheraient le terme (normalisation + frontières de mots)' do
    FactoryBot.create(:text_message, body: 'Votre VIREMENT est prêt', originated_by_app: true)
    FactoryBot.create(:text_message, body: 'il faut écarter ce cas', originated_by_app: true)
    FactoryBot.create(:text_message, body: 'un virement entrant', originated_by_app: false)

    service = described_class.new('Virement').call

    expect(service.matches_count).to eq(1)
  end

  it 'tronque les extraits autour du match et masque les numéros de téléphone' do
    FactoryBot.create(
      :text_message,
      body: "#{'a' * 100} rappelez le 0612345678 pour votre virement #{'z' * 100}",
      originated_by_app: true
    )

    service = described_class.new('virement').call

    expect(service.excerpts.first).to include('[num]')
    expect(service.excerpts.first).not_to include('0612345678')
    expect(service.excerpts.first.length).to be < 120
  end

  it 'masque les numéros avec séparateurs (espaces, points, tirets)' do
    FactoryBot.create(
      :text_message,
      body: 'Appelez le 06 12 34 56 78 pour votre virement',
      originated_by_app: true
    )
    FactoryBot.create(
      :text_message,
      body: 'Contactez +33.6.12.34.56.78 rapidement',
      originated_by_app: true
    )
    FactoryBot.create(
      :text_message,
      body: 'Numéro: 06-12-34-56-78 urgent',
      originated_by_app: true
    )

    service = described_class.new('virement').call

    expect(service.excerpts.first).to include('[num]')
    expect(service.excerpts.first).not_to include('06')
    expect(service.excerpts.first).not_to include('12')
    expect(service.excerpts.first).not_to include('34')
  end
end
