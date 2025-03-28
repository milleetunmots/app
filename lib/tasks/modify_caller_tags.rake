namespace :models do
  desc "Replace 'appelante' by 'accompagnante'"
  task modify_caller_models: :environment do
    Tag.where('name LIKE ?', '%appelante%').find_each do |tag|
      tag.update(name: tag.name.gsub('appelante', 'accompagnante'))
    end
    Media::Form.where('name LIKE ?', '%appelante%').find_each do |form|
      form.update(name: form.name.gsub('appelante', 'accompagnante'))
    end
    Source.where('name LIKE ?', '%Appelante%').find_each do |source|
      source.update(name: source.name.gsub('Appelante', 'Accompagnante'))
    end
  end
end
