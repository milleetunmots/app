class CreateRegistrationLinkRecords < ActiveRecord::Migration[6.1]
  def change
    RegistrationLink.create(url: '/inscriptioncaf', channel: 'caf', label: 'CAF')
    RegistrationLink.create(url: '/inscription3', channel: 'pmi', label: 'PMI')
    RegistrationLink.create(url: '/inscriptionmsa', channel: 'caf', label: 'MSA')
    RegistrationLink.create(url: '/inscription4', channel: 'bao', label: 'BAO')
    RegistrationLink.create(url: '/inscriptionpartenaires', channel: 'local_partner', label: 'Partenaires locaux')
  end
end
