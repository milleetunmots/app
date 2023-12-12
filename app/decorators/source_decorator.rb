class SourceDecorator < BaseDecorator

  def name
    name = model.channel == 'pmi' && model.department ? "[#{model.department}] #{model.name}" : model.name.to_s
    if model.name == 'Autre'
      h.link_to "#{name} - #{channel}", [:admin, model]
    else
      h.link_to name, [:admin, model]
    end
  end

  def channel
    Source.human_attribute_name("channel_list.#{model.channel}")
  end
end
