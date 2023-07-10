module Bubble
  class ImportBubbleVideoService

    def initialize
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/video")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
      @count = 0
    end

    def call
      all_videos.each do |item|
        video = Bubbles::BubbleVideo.find_or_create_by(bubble_video_attributes(item['_id']))

        @count += 1 if video.save!
      end
    end

    # private

    def all_videos
      response = HTTP.headers(@headers).get(@uri)
      return JSON.parse(response.body.to_s)['response']['results'] if response.code == 200

      raise "Impossible de récupérer toutes les vidéos de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end

    def retrieve_a_video(uid)
      module_uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/video/#{uid}")
      response = HTTP.headers(@headers).get(module_uri)
      return JSON.parse(response.body.to_s)['response'] if response.code == 200

      raise "Impossible de récupérer la vidéo #{uid} de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end

    def bubble_video_attributes(uid)
      video_retrieved = retrieve_a_video(uid)
      video_retrieved.slice('like', 'dislike', 'views', 'lien', 'video', 'types', 'avis_nouveaute', 'avis_pas_adapte', 'avis_rappel').merge('created_date' => video_retrieved['Created Date'])
    end
  end
end
