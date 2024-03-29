class Group

  class ProgramSmsToBilingualsService

    FIRST_MESSAGE = "Si vous parlez une autre langue que le français à la maison, c'est une chance pour votre enfant ! Sentez-vous libre de parler dans VOTRE LANGUE si vous êtes plus à l'aise, l'important c'est de lui parler souvent !".freeze
    SECOND_MESSAGE = "Un enfant qui entend d'autres langues que le français à la maison n'aura pas de retard de langage et apprendra le français le moment venu. Il peut mélanger plusieurs langues mais ne les confond pas. Je vous en dis plus dans cette vidéo ! {URL}".freeze
    THIRD_MESSAGE = "La maman d'Hanaé, qui parle le créole avec sa fille, témoigne : \"N'hésitez pas à partager ce que vous êtes, et ce que ses grands-parents sont, vos valeurs, en parlant vos langues maternelles, pour savoir d'où l'on vient et pour pouvoir avancer au mieux dans le futur.\" Et chez vous, quelle langue parlez-vous avec votre enfant ?".freeze
    # Retrieve the redirection target of Bilinguisme - Pour debuter - 12-17 media
    SECOND_MESSAGE_LINK_ID = RedirectionTarget.joins(:medium).find_by(media: { name: 'URLrecFSkjakLY8MWEvG' })&.id

    def initialize(group_id, first_message_date)
      @group = Group.find(group_id)
      @children = @group.bilingual_children.pluck(:id).map { |id| "child.#{id}" }
      @first_message_date = first_message_date
      @errors = []
    end

    def call
      raise "SECOND_MESSAGE_LINK_ID n'a pas pu être récupéré" unless SECOND_MESSAGE_LINK_ID

      program_message(date: @first_message_date, message: FIRST_MESSAGE)
      program_message(date: @first_message_date + 7.days, message: SECOND_MESSAGE, link_id: SECOND_MESSAGE_LINK_ID)
      program_message(date: @first_message_date + 14.days, message: THIRD_MESSAGE)

      self
    end

    private

    def program_message(date:, message:, link_id: nil, hour: '12:31', children: @children)
      return if @children.count.zero?

      service = ProgramMessageService.new(date, hour, children, message, nil, link_id).call
      raise service.errors.join("\n") if service.errors.any?
    end
  end
end
