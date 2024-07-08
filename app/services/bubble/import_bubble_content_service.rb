module Bubble
  class ImportBubbleContentService < BubbleService

    def initialize
      super('content')
    end

    def call
      all_contents.each do |item|
        item['content_type'] = item['type']
        new_content = fill_data(Bubbles::BubbleContent, item, %w[age titre content_type avis_nouveaute avis_pas_adapte avis_rappel description id_contenu])
        new_content.module_content = Bubbles::BubbleModule.find_by(bubble_id: item['module'].first) if item['module']
        new_content.save
      end
    end

    private

    def all_contents
      all_datas
    end
  end
end
