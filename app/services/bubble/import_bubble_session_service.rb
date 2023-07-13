module Bubble
  class ImportBubbleSessionService

    def initialize
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/session")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
    end

    def call
      all_sessions.each do |item|
        new_session = Bubbles::BubbleSession.find_or_create_by(bubble_session_attributes(item['_id']))
        new_session.module_session = Bubbles::BubbleModule.find_by(Bubble::ImportBubbleModuleService.new.bubble_module_attributes(item['module'])) if item['module']
        new_session.video = Bubbles::BubbleVideo.find_by(Bubble::ImportBubbleVideoService.new.bubble_video_attributes(item['video'])) if item['video']

        new_session.avis_contenu = bubble_session_updated_attribute(item['_id'], 'avis_contenu') if item['avis_contenu']
        new_session.avis_rappel = bubble_session_updated_attribute(item['_id'], 'avis_rappel') if item['avis_rappel']
        new_session.avis_video = bubble_session_updated_attribute(item['_id'], 'avis_video') if item['avis_video']
        new_session.pourcentage_video = bubble_session_updated_attribute(item['_id'], 'pourcentage_video') if item['pourcentage_video']

        new_session.save
      end
    end

    def bubble_session_attributes(uid)
      session_retrieved = retrieve_a_session(uid)
      session_retrieved.slice('lien', 'derniere_ouverture').merge('created_date' => session_retrieved['Created Date'], 'child_session' => session_retrieved['child_id'])
    end

    private

    def all_sessions
      all_datas = []
      items_count = 0
      params = { cursor: 0, constraints: [ { key: 'child_id', constraint_type: 'is_not_empty' } ] }
      loop do
        response = HTTP.headers(@headers).get(@uri, params: params)
        raise "Impossible de récupérer toutes les sesisons de bubble. Erreur lors de l'appel à l'API : #{response.code}" unless response.code == 200

        response = JSON.parse(response.body.to_s)['response']

        all_datas.concat response['results']
        items_count += response['count']
        items_remaining_count = response['remaining']
        break if items_remaining_count.zero?

        params[:cursor] = items_count
      end

      all_datas
    end

    def retrieve_a_session(uid)
      session_uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/session/#{uid}")
      response = HTTP.headers(@headers).get(session_uri)
      return JSON.parse(response.body.to_s)['response'] if response.code == 200

      raise "Impossible de récupérer la session #{uid} de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end

    def bubble_session_updated_attribute(uid, attribute)
      session_retrieved = retrieve_a_session(uid)
      session_retrieved.slice(attribute)[attribute]
    end
  end
end
