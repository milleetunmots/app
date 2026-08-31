require 'rails_helper'

RSpec.describe PhoneNormalizationConcern do
  describe '.canonical' do
    it 'ramène toutes les notations d\'un même numéro à la forme nationale' do
      [
        '0890123456',
        '08 90 12 34 56',
        '08.90.12.34.56',
        '0890-12-34-56',
        '+33890123456',
        '+33 8 90 12 34 56',
        '0033890123456',
        '00 33 8 90 12 34 56'
      ].each do |notation|
        expect(described_class.canonical(notation)).to eq('0890123456'),
                                                       "notation non canonicalisée : #{notation.inspect}"
      end
    end

    # Phonelib ne sait parser ni les préfixes ni les numéros courts : `national`
    # retombe sur l'entrée nettoyée, ce qui les laisse intacts.
    it 'laisse intacts les préfixes de tranche et les numéros courts' do
      { '089' => '089', '0810' => '0810', '118' => '118', '118 712' => '118712', '3900' => '3900' }.each do |input, expected|
        expect(described_class.canonical(input)).to eq(expected), "préfixe non conservé : #{input.inspect}"
      end
    end

    it 'ne conserve que les chiffres' do
      expect(described_class.canonical('tel : 0890/12/34/56')).to eq('0890123456')
    end

    it 'renvoie une chaîne vide pour une valeur absente ou sans chiffre' do
      expect(described_class.canonical(nil)).to eq('')
      expect(described_class.canonical('')).to eq('')
      expect(described_class.canonical('surtaxé')).to eq('')
    end
  end
end
