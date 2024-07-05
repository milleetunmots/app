module Bubble
  class ImportBubbleVideoService < BubbleService

    def initialize
      super('video')
    end

    def call
      all_videos.each do |item|
        item['video'] = item['Titre']
        item['video_type'] = item['type']
        fill_data(Bubbles::BubbleVideo, item, %w[like dislike views lien video video_type avis_nouveaute avis_pas_adapte avis_rappel])
      end
    end

    private

    def all_videos
      all_datas
    end
  end
end
