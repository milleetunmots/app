namespace :bubble_sessions do
  desc 'Add bubble content to bubble sessions'
  task add_content: :environment do
    Bubble::BubbleService.new('session').all_datas([{ key: 'contenu', constraint_type: 'is_not_empty' }]).each do |session|
      data = Bubbles::BubbleSession.find_by(bubble_id: session['_id'], created_date: session['Created Date'])
      unless data
        data = Bubbles::BubbleSession.create(bubble_id: session['_id'], created_date: session['Created Date'])
        %w[avis_contenu avis_video child_session derniere_ouverture lien pourcentage_video avis_rappel].each do |attribute|
          data.update_column(attribute.to_sym, session[attribute.to_s])
        end
        data.module_session = Bubbles::BubbleModule.find_by(bubble_id: session['module']) if session['module']
        data.video = Bubbles::BubbleVideo.find_by(bubble_id: session['video']) if session['video']
        data.content = Bubbles::BubbleContent.find_by(bubble_id: session['contenu']) if session['contenu']
        data.save
      end

      next if data.content

      data.content = Bubbles::BubbleContent.find_by(bubble_id: session['contenu'])
      data.save
    end

  end
end
