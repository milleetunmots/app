class ChildSupport::ChildrenDisengagementService

  MESSAGE = 'Bonjour, c’est {PRENOM_ACCOMPAGNANTE} de l’association 1001mots. J’ai essayé de vous appeler, mais on n’a pas pu discuter ensemble cette fois-ci. Cet appel avec moi est très important pour votre accompagnement. Mais ça fait 2 fois que ce n’est pas possible de discuter, donc l’accompagnement s’arrête et vous n’allez plus recevoir de livres ni de SMS. Je vous souhaite de beaux moments avec {PRENOM_DES_ENFANTS}. Et si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : {URL}'.freeze

  def initialize(group_id)
    @group = Group.find(group_id)
    @recipients = []
    @message_planned_timestamp = Time.zone.now.at_beginning_of_day + 13.hours
    @errors = []
  end

  def call
    return self if @group.type_of_support == 'without_calls'

    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('desengage-2appelsKO').uniq.each do |child_support|
      [child_support.parent1, child_support.parent2].each do |parent|
        next if parent.nil?

        unless child_support.supporter
          @errors << "Aucune accompagnante pour la fiche : #{child_support.id}"
          return self
        end

        if child_support.children.where(group: @group).empty?
          @errors << "Aucun enfant sur la fiche : #{child_support.id} dans la cohorte : #{@group.id}"
          return self
        end

        child_support.children.update(group_status: 'disengaged', group_end: Time.zone.today)
        child_support.save
        @message = MESSAGE.gsub('{PRENOM_ACCOMPAGNANTE}', child_support.supporter.decorate.first_name)
        @message = @message.gsub('{PRENOM_DES_ENFANTS}', child_support.children.where(group: @group).map(&:first_name).to_sentence)
        @message = @message.gsub('{URL}', "https://form.typeform.com/to/fysdS3Sd#st=#{parent.security_token}")
        event = Event.create(
          {
            related_id: parent.id,
            related_type: 'Parent',
            body: @message,
            type: 'Events::TextMessage',
            occurred_at: @message_planned_timestamp,
            message_provider: 'aircall',
            spot_hit_status: 0
          }
        )
        @recipients << {
          number_id: child_support.supporter.aircall_number_id,
          to: parent.phone_number,
          body: @message,
          event_id: event.id
        }
      end
    end
    Aircall::SendDisengagementMessageJob.set(wait_until: @message_planned_timestamp).perform_later(@recipients) if @recipients.any?
    self
  end
end
