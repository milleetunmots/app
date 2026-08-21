module ActiveAdmin::AllowedPatternsHelper

  def allowed_pattern_kind_select_collection
    AllowedPattern::KINDS.map { |kind| [AllowedPattern.human_attribute_name("kind.#{kind}"), kind] }
  end

  def allowed_pattern_match_type_select_collection(kind)
    match_types = AllowedPattern::MATCH_TYPES_BY_KIND[kind] || []
    match_types.map { |match_type| [AllowedPattern.human_attribute_name("match_type.#{match_type}"), match_type] }
  end
end
