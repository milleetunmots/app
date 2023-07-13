module Bubble
  class ImportBubbleModuleService

    def initialize
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/module")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
    end

    def call
      all_modules.each do |item|
        new_module = Bubbles::BubbleModule.find_or_create_by(bubble_module_attributes(item['_id']))
        new_module.module_precedent = Bubbles::BubbleModule.find_or_create_by(bubble_module_attributes(item['module_precedent'])) if item['module_precedent']
        new_module.module_suivant = Bubbles::BubbleModule.find_or_create_by(bubble_module_attributes(item['module_suivant'])) if item['module_suivant']
        new_module.video_princ = Bubbles::BubbleVideo.find_by(Bubble::ImportBubbleVideoService.new.bubble_video_attributes(item['video_princ'])) if item['video_princ']
        new_module.video_tem = Bubbles::BubbleVideo.find_by(Bubble::ImportBubbleVideoService.new.bubble_video_attributes(item['video_tem'])) if item['video_tem']

        new_module.save
      end
    end

    def bubble_module_attributes(uid)
      module_retrieved = retrieve_a_module(uid)
      module_retrieved.slice('age', 'description', 'titre', 'niveau', 'theme').merge('created_date' => module_retrieved['Created Date'])
    end

    private

    def all_modules
      response = HTTP.headers(@headers).get(@uri)
      return JSON.parse(response.body.to_s)['response']['results'] if response.code == 200

      raise "Impossible de récupérer tous les modules de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end

    def retrieve_a_module(uid)
      module_uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/module/#{uid}")
      response = HTTP.headers(@headers).get(module_uri)
      return JSON.parse(response.body.to_s)['response'] if response.code == 200

      raise "Impossible de récupérer le module #{uid} de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end
  end
end
