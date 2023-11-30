module ActiveAdmin::ChildrenHelper

  def child_gender_select_collection(with_unknown: false)
    if with_unknown
      [
        [
          Child.human_attribute_name('gender.x'),
          ''
        ]
      ]
    else
      []
    end + Child::GENDERS.map do |v|
      [
        Child.human_attribute_name("gender.#{v}"),
        v
      ]
    end
  end

  def child_group_select_collection
    Group.order(:name).map(&:decorate)
  end

  def child_group_status_select_collection
    Child::GROUP_STATUS.map do |v|
      [
        Child.human_attribute_name("group_status.#{v}"),
        v
      ]
    end
  end

  def child_parent_select_collection
    Parent.order(:first_name, :last_name).map(&:decorate)
  end

  def child_selection_collection
    Child.order(:first_name, :last_name).map(&:decorate)
  end

  def child_registration_source_select_collection
    Child::REGISTRATION_SOURCES.map do |v|
      [
        Child.human_attribute_name("registration_source.#{v}"),
        v
      ]
    end
  end

  def child_land_select_collection
    Child::LANDS
  end

  def child_registration_source_select_collection_for_pros
    [
      ['un·e professionnel·le de PMI', :pmi],
      ['un·e orthophoniste', :therapist],
      ['un·e professionnel·le de santé', :doctor],
      ['un·e autre partenaire de 1001mots (centre social, association, crèche...)', :other]
    ]
  end

  def child_registration_pmi_detail_collection
    Child::PMI_LIST.map { |v| [Child.human_attribute_name("pmi_detail.#{v}"), v] }.sort
  end

  def child_registration_source_details_suggestions
    Child.pluck('DISTINCT ON (LOWER(registration_source_details)) registration_source_details').compact.sort_by(&:downcase)
  end

  def child_supporter_select_collection
    AdminUser.order(:name).map(&:decorate)
  end

  def caf_form_received_from
    [
      ['La CAF', 'caf'],
      ['Mon entourage', 'bao']
    ]
  end

  def source_select_for_pmi
    Source.by_pmi.map { |pmi| [pmi.name, pmi.id] }
  end

  def source_select_for_caf
    Source.by_caf.map { |caf| [caf.name, caf.id] }
  end

  def source_select_for_bao
    Source.by_bao.map { |bao| [bao.name, bao.id] }
  end

  def source_select_for_local_partner
    Source.by_local_partner.map { |local_partner| [local_partner.name, local_partner.id] }
  end

  def local_partner_source_departements
    [['Ain', 1], ['Aisne', 2], ['Allier', 3], ['Alpes-de-Haute-Provence', 4], ['Hautes-Alpes', 5],
      ['Alpes-Maritimes', 6], ['Ardèche', 7], ['Ardennes', 8], ['Ariège', 9], ['Aube', 10],
      ['Aude', 11], ['Aveyron', 12], ['Bouches-du-Rhône', 13], ['Calvados', 14], ['Cantal', 15],
      ['Charente', 16], ['Charente-Maritime', 17], ['Cher', 18], ['Corrèze', 19], ['Côte-d\'Or', 21], ['Côtes-d\'Armor', 22], ['Creuse', 23], ['Dordogne', 24],
      ['Doubs', 25], ['Drôme', 26], ['Eure', 27], ['Eure-et-Loir', 28], ['Finistère', 29], ['Gard', 30],
      ['Haute-Garonne', 31], ['Gers', 32], ['Gironde', 33], ['Hérault', 34], ['Ille-et-Vilaine', 35],
      ['Indre', 36], ['Indre-et-Loire', 37], ['Isère', 38], ['Jura', 39], ['Landes', 40], ['Loir-et-Cher', 41],
      ['Loire', 42], ['Haute-Loire', 43], ['Loiret', 45], ['Lot', 46], ['Lot-et-Garonne', 47], ['Lozère', 48],
      ['Maine-et-Loire', 49], ['Manche', 50], ['Marne', 51], ['Haute-Marne', 52], ['Mayenne', 53],
      ['Meurthe-et-Moselle', 54], ['Meuse', 55], ['Morbihan', 56], ['Moselle', 57], ['Nièvre', 58],
      ['Nord', 59], ['Oise', 60], ['Orne', 61], ['Pas-de-Calais', 62], ['Puy-de-Dôme', 63],
      ['Pyrénées-Atlantiques', 64], ['Hautes-Pyrénées', 65], ['Pyrénées-Orientales', 66],
      ['Bas-Rhin', 67], ['Haut-Rhin', 68], ['Rhône', 69], ['Haute-Saône', 70], ['Saône-et-Loire', 71],
      ['Sarthe', 72], ['Savoie', 73], ['Haute-Savoie', 74], ['Paris', 75], ['Seine-Maritime', 76],
      ['Seine-et-Marne', 77], ['Yvelines', 78], ['Deux-Sèvres', 79], ['Somme', 80], ['Tarn', 81],
      ['Tarn-et-Garonne', 82], ['Var', 83], ['Vaucluse', 84], ['Vendée', 85], ['Vienne', 86],
      ['Haute-Vienne', 87], ['Vosges', 88], ['Yonne', 89], ['Territoire de Belfort', 90],
      ['Essonne', 91], ['Hauts-de-Seine', 92], ['Seine-Saint-Denis', 93], ['Val-de-Marne', 94],
      ['Val-d\'Oise', 95]]
  end
end
