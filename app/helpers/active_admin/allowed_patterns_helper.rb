module ActiveAdmin::AllowedPatternsHelper

  # Le format attendu pour `value` dépend du couple (kind, match_type) : cf.
  # AllowedPattern#value_format_matches_match_type.
  VALUE_HINTS = {
    'url/domain' => 'Un domaine, sans schéma ni chemin (ex: monpartenaire.fr). Les sous-domaines sont également autorisés.',
    'url/exact' => 'Une URL complète, avec son schéma (ex: https://exemple.fr/page).',
    'phone_number/exact' => "Le numéro autorisé, dans n'importe quelle notation (0810123456, +33 810 12 34 56)."
  }.freeze

  def allowed_pattern_kind_select_collection
    AllowedPattern::KINDS.map { |kind| [AllowedPattern.human_attribute_name("kind.#{kind}"), kind] }
  end

  # Toutes les options sont rendues, chacune étiquetée des kinds auxquels elle
  # s'applique : le kind se choisit côté client, c'est donc admin/allowed_patterns.js
  # qui restreint la liste au kind sélectionné. Un même match_type peut valoir pour
  # plusieurs kinds (`exact` sert aux URLs comme aux numéros), d'où data-kinds au
  # pluriel.
  def allowed_pattern_match_type_select_collection
    kinds_by_match_type = Hash.new { |hash, key| hash[key] = [] }
    AllowedPattern::MATCH_TYPES_BY_KIND.each do |kind, match_types|
      match_types.each { |match_type| kinds_by_match_type[match_type] << kind }
    end

    kinds_by_match_type.map do |match_type, kinds|
      [AllowedPattern.human_attribute_name("match_type.#{match_type}"), match_type, { data: { kinds: kinds.join(' ') } }]
    end
  end

  # Pour la même raison que les match_types : le couple se choisit côté client, on
  # expose donc tous les hints au formulaire et admin/allowed_patterns.js affiche
  # celui du couple sélectionné.
  def allowed_pattern_value_hints
    VALUE_HINTS
  end

  # Hint rendu côté serveur : celui du pattern édité, ou celui de la sélection par
  # défaut du formulaire (première option de chaque select) sur un nouveau pattern.
  # Sans ça, le hint affiché avant l'exécution du script ne correspondrait pas aux
  # selects.
  def allowed_pattern_value_hint(allowed_pattern)
    VALUE_HINTS.fetch(allowed_pattern_value_hint_key(allowed_pattern)) { VALUE_HINTS[default_allowed_pattern_value_hint_key] }
  end

  private

  def allowed_pattern_value_hint_key(allowed_pattern)
    return default_allowed_pattern_value_hint_key if allowed_pattern.kind.blank? || allowed_pattern.match_type.blank?

    "#{allowed_pattern.kind}/#{allowed_pattern.match_type}"
  end

  def default_allowed_pattern_value_hint_key
    kind = AllowedPattern::KINDS.first
    "#{kind}/#{AllowedPattern::MATCH_TYPES_BY_KIND[kind].first}"
  end
end
