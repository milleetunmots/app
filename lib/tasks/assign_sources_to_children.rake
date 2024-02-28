require 'csv'

PMI_DETAILS_MATCHING_SOURCES = {
  'trappes' => 'PMI Trappes',
  'val_de_saone_dombes' => 'PMI Val de Saône Dombes',
  'montargis' => 'PMI Montargis',
  'les_mureaux' => 'PMI Les Mureaux',
  'asnieres_gennevilliers_sst2' => 'PMI Asnières/ Gennevilliers - Pôle social',
  'bugey_pays_de_gex' => 'PMI Bugey Pays de Gex',
  'chanteloup' => 'PMI Chanteloup-les-Vignes',
  'gennevilliers_timsit' => 'PMI Gennevilliers - Timsit',
  'mantes_la_jolie_leclerc' => 'PMI Mantes-la-Jolie Leclerc',
  'plaisir' => 'PMI Plaisir',
  'villeneuve_la_garenne' => 'PMI Villeneuve-la-Garenne',
  'plaine_de_l_ain_cotiere' => "PMI Plaine de l'Ain Côtière",
  'orleans_est' => 'PMI Orléans Est',
  'orleans' => 'PMI Orléans',
  'sartrouville' => 'PMI Sartrouville',
  'mantes_la_jolie_clemenceau' => 'PMI Mantes-la-Jolie Clémenceau',
  'forbach' => 'PMI Forbach',
  'gien' => 'PMI Gien',
  'gennevilliers_zucman_gabison' => 'PMI Gennevilliers - Zucman-Gabison',
  'pithiviers' => 'PMI Pithiviers',
  'sarreguemines' => 'PMI Sarreguemines',
  'seine_st_denis' => 'PMI 93 Circonscription de Montfermeil/Clichy sous Bois/Coubron',
  'olivet' => 'PMI Olivet',
  'vernouillet' => 'PMI Vernouillet',
  'bresse_revermont' => 'PMI Bresse Revermont'
}.freeze

CANAL_MATCHING = {
  'PMI' => 'pmi',
  'BAO' => 'bao',
  'CAF' => 'caf',
  'Partenaires Locaux' => 'local_partner',
  'Autre' => 'other'
}.freeze

def caf_territory_matching(territory)
  case territory
  when 'Loiret'
    Source.find_by(channel: 'caf', name: 'CAF Loiret')
  when 'Seine-Saint-Denis'
    Source.find_by(channel: 'caf', name: 'CAF 93')
  when 'Paris'
    Source.find_by(channel: 'caf', name: 'CAF Paris')
  when 'Moselle'
    Source.find_by(channel: 'caf', name: 'CAF Moselle')
  when 'Yvelines'
    Source.find_by(channel: 'caf', name: 'CAF 93')
  end
end

def pmi_loiret_matching(registration_source_details)
  registration_source_details = registration_source_details.delete(' ').downcase
  lines = CSV.read(ENV['PMI_LOIRET_CSV_PATH'])
  lines.each do |line|
    name = registration_source_details == "#{line[0]}#{line[1]}".downcase.delete(' ') ? "#{line[0]}#{line[1]}".downcase.delete(' ') : nil
    name = registration_source_details == "#{line[1]}#{line[0]}".downcase.delete(' ') ? "#{line[1]}#{line[0]}".downcase.delete(' ') : nil
    next unless registration_source_details == name

    return Source.find_by(name: line[2])
  end
  nil
end

def matching(file, registration_source_details)
  lines = CSV.read(file)
  lines.each do |line|
    next unless registration_source_details.strip == line[0].strip

    return CANAL_MATCHING[line[1]&.strip] == 'other' ? Source.find_by(channel: CANAL_MATCHING[line[1]&.strip]) : Source.find_by(channel: CANAL_MATCHING[line[1]&.strip], name: line[2])
  end
  nil
end

namespace :sources do
	desc 'Assign Sources to children, matching as closely as we can their registration_source / details'
	task assign_to_children: :environment do
    children_without_matching_source = []
		Child.all.find_each do |child|
      matching_source =
        case child.registration_source
        when 'pmi'
          pmi_loiret_matching(child.registration_source_details) ||Source.find_by(channel: 'pmi', name: PMI_DETAILS_MATCHING_SOURCES[child.pmi_detail]) || Source.find_by(channel: 'other')
        when 'caf'
          caf_territory_matching(child.decorate.territory) || Source.find_by(channel: 'other')
        when 'resubscribing'
          Source.find_by(channel: 'bao', name: 'Je suis déjà inscrit à 1001mots')
        when 'friends'
          Source.find_by(channel: 'bao', name: 'Mon entourage')
        when 'other'
          matching(ENV['OTHER_CSV_PATH'], child.registration_source_details) || Source.find_by(channel: 'other')
        when 'nursery', 'therapist', 'doctor'
          matching(ENV['NURSERY_CSV_PATH'], child.registration_source_details) ||
            matching(ENV['THERAPIST_CSV_PATH'], child.registration_source_details) ||
            matching(ENV['DOCTOR_CSV_PATH'], child.registration_source_details) ||
            Source.find_by(channel: 'local_partner', name: 'Autre')
        else
          Source.find_by(channel: 'other')
        end
      children_without_matching_source << child.id and next if matching_source.blank?

      children_source = ChildrenSource.find_by(child: child)
      ChildrenSource.create!(child: child, source: matching_source, details: child.registration_source_details) and next unless children_source
      children_source.update(source: matching_source, details: child.registration_source_details) if children_source.source.channel == 'other'
		end
    puts "CHILDREN WITHOUT MATCHING SOURCE :"
    puts children_without_matching_source.inspect
	end
end
