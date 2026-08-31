module ActiveAdmin::AllowedPatternsHelper

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
end
