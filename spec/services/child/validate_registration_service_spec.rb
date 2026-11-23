require 'rails_helper'

RSpec.describe Child::ValidateRegistrationService do
  let(:source) { FactoryBot.create(:source) }
  let(:child) { FactoryBot.build(:child) }
  let(:parent) { { first_name: 'Paul', last_name: 'Martin', phone_number: '0612345678', gender: 'm' } }

  def validate(present_parents:, postal_code: '75011', source_id: source.id)
    described_class.new(child, present_parents: present_parents, parent1_postal_code: postal_code, source_id: source_id).call
    child.errors
  end

  it "n'ajoute aucune erreur pour une inscription complète" do
    expect(validate(present_parents: { 1 => parent })).to be_empty
  end

  it 'exige au moins un parent' do
    expect(validate(present_parents: {}).full_messages).to include('Au moins un parent est obligatoire.')
  end

  it "signale chaque champ manquant d'un parent saisi, avec son numéro" do
    errors = validate(present_parents: { 2 => parent.merge(first_name: '', gender: 'x') })

    expect(errors.attribute_names).to include(:parent2_first_name, :parent2_gender)
  end

  it 'refuse une source inactive et un code postal outre-mer' do
    errors = validate(present_parents: { 1 => parent }, postal_code: '97400', source_id: 0)

    expect(errors.attribute_names).to include(:source)
    expect(errors.full_messages).to include(a_string_including('pas encore disponible dans votre région'))
  end
end
