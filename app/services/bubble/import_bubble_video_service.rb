module Bubble
  class ImportBubbleVideoService

    def initialize
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/video")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
    end

    def call
      all_videos.each do |item|
        new_video = Bubbles::BubbleVideo.find_or_create_by(bubble_video_attributes(item['_id']))
        new_video.avis_nouveaute = bubble_video_updated_attribute(item['_id'], 'avis_nouveaute') if item['avis_nouveaute']
        new_video.avis_pas_adapte = bubble_video_updated_attribute(item['_id'], 'avis_pas_adapte') if item['avis_pas_adapte']
        new_video.avis_rappel = bubble_video_updated_attribute(item['_id'], 'avis_rappel') if item['avis_rappel']
        new_video.like = bubble_video_updated_attribute(item['_id'], 'like') if item['like']
        new_video.dislike = bubble_video_updated_attribute(item['_id'], 'dislike') if item['dislike']
        new_video.avis_rappel = bubble_video_updated_attribute(item['_id'], 'views') if item['views']

        new_video.save
      end
    end

    def bubble_video_attributes(uid)
      video_retrieved = retrieve_a_video(uid)
      video_retrieved.slice('lien', 'video').merge('created_date' => video_retrieved['Created Date'], 'video_type' => video_retrieved['type'])
    end

    private

    def all_videos
      all_datas = []
      params = { cursor: 0 }
      loop do
        response = HTTP.headers(@headers).get(@uri, params: params)
        raise "Impossible de récupérer toutes les vidéos de bubble. Erreur lors de l'appel à l'API : #{response.code}" unless response.code == 200

        response = JSON.parse(response.body.to_s)['response']

        all_datas.concat response['results']
        items_count = response['count']
        items_remaining_count = response['remaining']
        break if items_remaining_count.zero?

        params[:cursor] = items_count
      end

      all_datas
    end

    def retrieve_a_video(uid)
      video_uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/video/#{uid}")
      response = HTTP.headers(@headers).get(video_uri)
      return JSON.parse(response.body.to_s)['response'] if response.code == 200

      raise "Impossible de récupérer la vidéo #{uid} de bubble. Erreur lors de l'appel à l'API : #{response.code}"
    end

    def bubble_video_updated_attribute(uid, attribute)
      video_retrieved = retrieve_a_video(uid)
      video_retrieved.slice(attribute)[attribute]
    end
  end
end
