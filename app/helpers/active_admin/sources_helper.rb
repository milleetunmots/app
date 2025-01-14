module ActiveAdmin::SourcesHelper

  def source_select_for_pmi(dpt = nil)
    if dpt.nil?
      Source.active.by_pmi.map { |pmi| [pmi.decorate.name, pmi.id] }
    else
      Source.active.by_pmi.where(department: dpt).map { |pmi| [pmi.decorate.name, pmi.id] }
    end
  end

  def source_select_for_caf
    Source.active.by_caf.map { |caf| [caf.name, caf.id] }
  end

  def source_select_for_bao
    Source.active.by_bao.map { |bao| [bao.name, bao.id] }
  end

  def source_select_for_local_partner
    sources_without_other = Source.active.by_local_partner.reject { |local_partner| local_partner.name == 'Autre' }
    other = Source.active.by_local_partner.select { |local_partner| local_partner.name == 'Autre' }

    (sources_without_other + other).map { |local_partner| [local_partner.name, local_partner.id] }
  end

  def source_channel_select_collection
    Source::CHANNEL_LIST.map { |channel| [Source.human_attribute_name("channel_list.#{channel}"), channel] }.sort
  end

  def source_select_collection
    Source.order(channel: :desc, department: :asc, name: :asc).map { |source| [source.decorate.name, source.id] }
  end

  def source_active_select_collection
    Source.active.order(channel: :desc, department: :asc, name: :asc).map { |source| [source.decorate.name, source.id] }
  end

  def source_details_suggestions
    ChildrenSource.select('DISTINCT ON (LOWER(details)) details').pluck(:details).uniq.compact.sort_by(&:downcase).reject(&:blank?)
  end
end
