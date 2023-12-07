class SourceDecorator < BaseDecorator

  def name
    name = model.channel == 'pmi' && model.department ? "[#{model.department}] #{model.name}" : model.name.to_s
    if model.name == 'Autre'
      "#{name} - #{channel}"
    else
      name
    end
  end

  def channel
    Source.human_attribute_name("channel_list.#{model.channel}")
  end
end
