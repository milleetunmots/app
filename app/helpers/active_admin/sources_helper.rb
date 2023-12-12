module ActiveAdmin::SourcesHelper

  def source_select_for_pmi(dpt = nil)
    if dpt.nil?
      Source.by_pmi.map { |pmi| [pmi.decorate.name, pmi.id] }
    else
      Source.by_pmi.where(department: dpt).map { |pmi| [pmi.decorate.name, pmi.id] }
    end
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

  def source_channel_select_collection
    Source::CHANNEL_LIST.map { |channel| [Source.human_attribute_name("channel_list.#{channel}"), channel] }.sort
  end

  def source_select_collection
    Source.all.map { |source| [source.decorate.name, source.id] }.sort
  end

  def source_details_suggestions
    ChildrenSource.pluck('DISTINCT ON (LOWER(details)) details').compact.sort_by(&:downcase)
  end
end
