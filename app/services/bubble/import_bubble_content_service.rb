module Bubble
  class ImportBubbleContentService

    def initialize
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/content")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
    end

    def call
      all_contents.each do |item|
        new_content = Bubbles::BubbleContent.find_or_create_by(bubble_content_attributes(item['_id']))
        new_content.module_content = Bubbles::BubbleModule.find_by(Bubble::ImportBubbleModuleService.new.bubble_module_attributes(item['module'].first)) if item['module']
        new_content.avis_nouveaute = bubble_content_updated_attribute(item['_id'], 'avis_nouveaute') if item['avis_nouveaute']
        new_content.avis_pas_adapte = bubble_content_updated_attribute(item['_id'], 'avis_pas_adapte') if item['avis_pas_adapte']
        new_content.avis_rappel = bubble_content_updated_attribute(item['_id'], 'avis_rappel') if item['avis_rappel']
      end
    end

    def bubble_content_attributes(uid)
      content_retrieved = retrieve_a_content(uid)
      content_retrieved.slice('age', 'titre', 'description').merge('created_date' => content_retrieved['Created Date'], 'content_type' => content_retrieved['type'])
    end

    private

    def all_contents
      all_datas = []
      params = { cursor: 0 }
      loop do
        response = HTTP.headers(@headers).get(@uri, params: params)
        raise "Impossible de récupérer tous les 'content' de bubble. Erreur lors de l'appel à l'API : #{response.code}" unless response.code == 200

        response = JSON.parse(response.body.to_s)['response']

        all_datas.concat response['results']
        items_count = response['count']
        items_remaining_count = response['remaining']
        break if items_remaining_count.zero?

        params[:cursor] = items_count
      end

      all_datas
    end

    def retrieve_a_content(uid)
      content_uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/content/#{uid}")
      response = HTTP.headers(@headers).get(content_uri)
      return JSON.parse(response.body.to_s)['response'] if response.code == 200

      raise "Impossible de récupérer le 'content' #{uid} de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end

    def bubble_content_updated_attribute(uid, attribute)
      content_retrieved = retrieve_a_content(uid)
      content_retrieved.slice(attribute)[attribute]
    end
  end
end
