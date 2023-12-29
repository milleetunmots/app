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
    Source.find_by(channel: 'caf', name: 'CAF 78')
  end
end

namespace :sources do
	desc 'Assign Sources to children, matching as closely as we can their registration_source / details'
	task assign_to_children: :environment do
    children_without_matching_source = []
		Child.all.find_each do |child|
      matching_source =
        case child.registration_source
        when 'pmi'
          Source.find_by(channel: 'pmi', name: PMI_DETAILS_MATCHING_SOURCES[child.pmi_detail])
        when 'caf'
          caf_territory_matching(child.decorate.territory)
        when 'resubscribing'
          Source.find_by(channel: 'bao', name: 'Je suis déjà inscrit à 1001mots')
        when 'friends'
          Source.find_by(channel: 'bao', name: 'Mon entourage')
        when 'other'
          Source.find_by(channel: 'bao', name: 'Autre')
        when 'nursery'
        when 'therapist'
        when 'doctor'
        end
      children_without_matching_source << child.id and next if matching_source.blank?

      ChildrenSource.create!(child: child, source: matching_source, details: child.registration_source_details)
		end
    puts "CHILDREN WITHOUT MATCHING SOURCE :"
    puts children_without_matching_source.inspect
	end
end
