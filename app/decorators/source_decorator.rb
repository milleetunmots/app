class SourceDecorator < BaseDecorator

  def name
    if model.channel == 'pmi' && model.department
      "[#{model.department}] #{model.name}"
    else
      model.name.to_s
    end
  end

  def channel
    Source.human_attribute_name("channel_list.#{model.channel}")
  end
end
