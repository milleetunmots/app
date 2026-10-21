require 'rails_helper'
require 'ostruct'

RSpec.describe 'Sentry : masquage du texte sensible dans le corps de requête' do
  let(:configuration) { OpenStruct.new }
  let(:before_send) { configuration.before_send }
  let(:corps) do
    { 'child_support' => { 'sensitive_information' => 'Père placé en foyer', 'notes' => 'Appel du matin' }, 'password' => 'secret' }
  end

  def evenement_avec(donnees)
    OpenStruct.new(request: OpenStruct.new(data: donnees))
  end

  before do
    stub_const('ENV', ENV.to_h.merge('SENTRY_DSN' => 'https://cle@example.com/1'))
    allow(Sentry).to receive(:init).and_yield(configuration)
    load Rails.root.join('config/initializers/sentry.rb')
  end

  it 'masque sensitive_information dans le corps de la requête' do
    evenement = before_send.call(evenement_avec(corps), {})

    expect(evenement.request.data['child_support']['sensitive_information']).to eq('[FILTERED]')
  end

  it 'masque le champ même à un niveau d’imbrication différent' do
    evenement = before_send.call(evenement_avec({ 'sensitive_information' => 'Père placé en foyer' }), {})

    expect(evenement.request.data['sensitive_information']).to eq('[FILTERED]')
  end

  it 'garde les autres champs et masque les mots de passe' do
    evenement = before_send.call(evenement_avec(corps), {})

    expect(evenement.request.data['child_support']['notes']).to eq('Appel du matin')
    expect(evenement.request.data['password']).to eq('[FILTERED]')
  end

  it 'laisse intact un corps qui n’est pas un hash' do
    evenement = before_send.call(evenement_avec('Skipped non-rewindable request body'), {})

    expect(evenement.request.data).to eq('Skipped non-rewindable request body')
  end

  it 'accepte un événement sans requête' do
    evenement = OpenStruct.new(request: nil)

    expect(before_send.call(evenement, {})).to eq(evenement)
  end

  it 'continue d’ignorer les erreurs de routage des robots' do
    erreur = ActionController::RoutingError.new('No route matches [GET] "/wp-login.php"')

    expect(before_send.call(evenement_avec(corps), { exception: erreur })).to be_nil
  end
end
