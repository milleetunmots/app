task create_source: :environment do
  Source.find_or_create_by(name: 'CAF Paris', channel: 'caf', department: 75, utm: '75')
  Source.find_or_create_by(name: 'CAF 78', channel: 'caf', department: 78, utm: '78')
  Source.find_or_create_by(name: 'CAF 93', channel: 'caf', department: 93, utm: '93')
  Source.find_or_create_by(name: 'CAF Moselle', channel: 'caf', department: 57, utm: '57')
  Source.find_or_create_by(name: 'CAF Loiret', channel: 'caf', department: 45, utm: '45')
  Source.find_or_create_by(name: 'PMI Plaisir', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Trappes', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Mantes-la-Jolie Clémenceau', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Mantes-la-Jolie Leclerc', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Chanteloup-les-Vignes', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Les Mureaux', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: "PMI Val d'Oise", channel: 'pmi', department: 95)
  Source.find_or_create_by(name: 'PMI Die', channel: 'pmi', department: 26)
  Source.find_or_create_by(name: 'PMI Livron/Loriol', channel: 'pmi', department: 26)
  Source.find_or_create_by(name: 'PMI Chabeuil', channel: 'pmi', department: 26)
  Source.find_or_create_by(name: 'PMI Vernouillet', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Sartrouville', channel: 'pmi', department: 78)
  Source.find_or_create_by(name: "PMI d'Elancourt", channel: 'pmi', department: 78)
  Source.find_or_create_by(name: 'PMI Orléans Est', channel: 'pmi', department: 45)
  Source.find_or_create_by(name: 'PMI Olivet', channel: 'pmi', department: 45)
  Source.find_or_create_by(name: 'PMI Orléans', channel: 'pmi', department: 45)
  Source.find_or_create_by(name: 'PMI Montargis', channel: 'pmi', department: 45)
  Source.find_or_create_by(name: 'PMI Gien', channel: 'pmi', department: 45)
  Source.find_or_create_by(name: 'PMI Pithiviers', channel: 'pmi', department: 45)
  Source.find_or_create_by(name: 'PMI Sarreguemines', channel: 'pmi', department: 57)
  Source.find_or_create_by(name: 'PMI 93 Circonscription de Montfermeil/Clichy sous Bois/Coubron', channel: 'pmi', department: 93)
  Source.find_or_create_by(name: 'PMI Forbach', channel: 'pmi', department: 57)
  Source.find_or_create_by(name: 'CS Aulnay', channel: 'pmi', department: 93)
  Source.find_or_create_by(name: 'PMI Gennevilliers - Zucman-Gabison', channel: 'pmi', department: 92)
  Source.find_or_create_by(name: 'PMI Gennevilliers - Timsit', channel: 'pmi', department: 92)
  Source.find_or_create_by(name: 'PMI Asnières/ Gennevilliers - Pôle social', channel: 'pmi', department: 92)
  Source.find_or_create_by(name: 'PMI Villeneuve-la-Garenne', channel: 'pmi', department: 92)
  Source.find_or_create_by(name: 'PMI Val de Saône Dombes', channel: 'pmi', department: 1)
  Source.find_or_create_by(name: "PMI Plaine de l'Ain Côtière", channel: 'pmi', department: 1)
  Source.find_or_create_by(name: 'PMI Bugey Pays de Gex', channel: 'pmi', department: 1)
  Source.find_or_create_by(name: 'PMI Bresse Revermont', channel: 'pmi', department: 1)
  Source.find_or_create_by(name: 'CMP Vaulx-en-Velin ', channel: 'local_partner', department: 69)
  Source.find_or_create_by(name: 'Santé Commune Vaulx-en-Velin', channel: 'local_partner', department: 69)
  Source.find_or_create_by(name: 'Crescendo', channel: 'local_partner', department: 75)
  Source.find_or_create_by(name: 'Generali - The Human Safety Net - Espace Bébés Parents', channel: 'local_partner')
  Source.find_or_create_by(name: 'Generali - The Human Safety Net - Maison des familles', channel: 'local_partner')
  Source.find_or_create_by(name: 'Generali - The Human Safety Net - Autre', channel: 'local_partner')
  Source.find_or_create_by(name: 'Hopital Robert Debré - Néonatologie', channel: 'local_partner', department: 75)
  Source.find_or_create_by(name: 'Hopital Robert Debré - Pedopsychiatrie', channel: 'local_partner', department: 75)
  Source.find_or_create_by(name: 'Hopital Robert Debré - Maternité', channel: 'local_partner', department: 75)
  Source.find_or_create_by(name: 'Centre Municipal de Santé de Bagnolet', channel: 'local_partner', department: 93)
  Source.find_or_create_by(name: 'Armée du Salut', channel: 'local_partner', department: 75)
  Source.find_or_create_by(name: 'CSA Argenteuil', channel: 'local_partner', department: 95)
  Source.find_or_create_by(name: "France Terre d'Asile", channel: 'local_partner', department: 93)
  Source.find_or_create_by(name: 'Ville de Grigny - service petite enfance', channel: 'local_partner', department: 91)
  Source.find_or_create_by(name: 'Professionnel(le) de santé en libéral - hors centre de santé', channel: 'local_partner')
  Source.find_or_create_by(name: 'Accompagnantes 1001mots', channel: 'local_partner')
  Source.find_or_create_by(name: 'Croix rouge - Espace Bébé Parents', channel: 'local_partner')
  Source.find_or_create_by(name: 'Autre', channel: 'local_partner')
  Source.find_or_create_by(name: 'Mon entourage', channel: 'bao', utm: 'friends')
  Source.find_or_create_by(name: 'Je suis déjà inscrit à 1001mots', channel: 'bao')
  Source.find_or_create_by(name: 'Autre', channel: 'bao')
  Source.find_or_create_by(name: 'Autre', channel: 'other')
end
