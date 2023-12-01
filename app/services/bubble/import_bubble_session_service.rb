module Bubble
  class ImportBubbleSessionService < BubbleService

    def initialize
      super('session')
      @import_date = Time.zone.now
      @latest_import_date = Bubbles::BubbleSession.maximum(:import_date)
    end

    def call
      all_sessions.each do |item|
        new_session = fill_data(Bubbles::BubbleSession, item, %w[avis_contenu avis_video child_session derniere_ouverture lien pourcentage_video avis_rappel])
        new_session.module_session = Bubbles::BubbleModule.find_by(bubble_id: item['module']) if item['module']
        new_session.video = Bubbles::BubbleVideo.find_by(bubble_id: item['video']) if item['video']
        new_session.content = Bubbles::BubbleContent.find_by(titre: item['contenu']) if item['contenu']
        new_session.import_date = @import_date
        new_session.save
      end
    end

    private

    def all_sessions
      all_datas([{ key: 'child_id', constraint_type: 'is_not_empty' }, { key: 'Modified Date', constraint_type: 'greater than', value: @latest_import_date&.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }])
    end
  end
end
