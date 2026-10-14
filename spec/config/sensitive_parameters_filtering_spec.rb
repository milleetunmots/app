require 'rails_helper'

RSpec.describe 'Masquage du texte sensible dans les journaux et les rapports d’erreurs' do
  let(:parametres) do
    { 'child_support' => { 'sensitive_information' => 'Père placé en foyer', 'notes' => 'Appel du matin', 'ok_for_solicitation' => 'false' } }
  end

  describe 'journaux Rails (et Sentry, qui reprend la même liste)' do
    let(:filtre) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

    it 'masque sensitive_information' do
      filtre_applique = filtre.filter(parametres)

      expect(filtre_applique['child_support']['sensitive_information']).to eq('[FILTERED]')
    end

    it 'ne masque pas les autres champs de la fiche' do
      filtre_applique = filtre.filter(parametres)

      expect(filtre_applique['child_support']['notes']).to eq('Appel du matin')
      expect(filtre_applique['child_support']['ok_for_solicitation']).to eq('false')
    end
  end

  describe 'Rollbar' do
    it 'masque sensitive_information dans les paramètres de requête' do
      expect(Rollbar.configuration.scrub_fields).to include(:sensitive_information)
    end

    it 'garde les champs masqués par défaut' do
      expect(Rollbar.configuration.scrub_fields).to include(:password, :secret)
    end
  end
end
