class Group

  class StopSupportService

    MORE_THAN_THIRTY_SIX_SMS = 'Votre enfant a 3 ans, c’est la fin des SMS et des livres 1001mots pour {PRENOM_ENFANT}. Nous espérons que ça vous a apporté des idées et de la confiance en vous en tant que parent ! Pour retrouver plein d’autres conseils RDV sur cette page {URL}. Je vous souhaite une bonne continuation et plein de beaux moments avec votre enfant !'.freeze
    END_SUPPORT_LINK = 'https://magical-bull-428.notion.site/C-est-la-fin-des-SMS-et-des-livres-1001mots-2826d144b6b04e658f4ea090529fb708?pvs=4'.freeze

    def initialize(group_id, initial_modules = false)
      @group = Group.find(group_id)
      @olders_children = initial_modules ? @group.children.more_than_thirty_six : @group.children.more_than_thirty_five # TODO, Explications
      @link_id = RedirectionTarget.joins(:medium).where(media: { url: END_SUPPORT_LINK }).first.id
      @errors = []
    end

    def call
      send_end_of_support_message
      stop_supports

      self
    end

    private

    def send_end_of_support_message
      return if @olders_children.count.zero?

      check_credits(MORE_THAN_THIRTY_SIX_SMS, @olders_children.count)
      raise "Impossible de programmer les messages de fin d'accompagnement car il n'y a pas assez de crédit spot-hit" if @errors.any?

      program_message(message: MORE_THAN_THIRTY_SIX_SMS, children: @olders_children)
    end

    def stop_supports
      @olders_children.each { |child| child.update(group_status: 'stopped', group_end: Time.zone.today) }
    end

    def sms_count(message, children_count)
      sms_to_send_count = 0
      sms_to_send_count += (message.gsub('{URL}', 'https://app.1001mots.org/r/xxxxxx/xx').size / 160) + 1
      sms_to_send_count *= children_count
      sms_to_send_count
    end

    def check_credits(message, children_count)
      credit_service = SpotHit::GetCreditsService.new.call
      raise credit_service.errors.join('\n') if credit_service.errors.any?

      return if sms_count(message, children_count) <= credit_service.sms

      @errors << "Pas assez de crédits sms sur SPOT-HIT : #{@sms_to_send_count} crédits sont nécéssaires."
      AdminUser.all_logistics_team_members.each do |ltm|
        Task.create(
          assignee_id: ltm.id,
          title: "Il n'y a pas assez de crédits pour la programmation des messages de fin d'accompagnement de la cohorte : \"#{@group.name}\"",
          description: @errors.join('\n'),
          due_date: Time.zone.today
        )
      end
    end

    def program_message(children:, message:, date: Time.zone.today, link_id: @link_id, hour: '12:30')
      service = ProgramMessageService.new(date, hour, children.map { |child| "child.#{child.id}" }, message, nil, link_id).call
      raise service.errors.join("\n") if service.errors.any?
    end
  end
end
