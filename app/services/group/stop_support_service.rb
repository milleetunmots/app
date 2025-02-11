class Group

  class StopSupportService

    END_OF_SUPPORT_SMS = 'C’est maintenant la fin des SMS et des livres 1001mots pour {PRENOM_ENFANT}. Nous espérons que ça vous a apporté des idées et de la confiance en vous en tant que parent ! Pour retrouver plein d’autres conseils RDV sur cette page {URL}. Je vous souhaite une bonne continuation et plein de beaux moments avec votre enfant !'.freeze
    MORE_THAN_THIRTY_SIX_SMS = 'Votre enfant a 3 ans, c’est la fin des SMS et des livres 1001mots pour {PRENOM_ENFANT}. Nous espérons que ça vous a apporté des idées et de la confiance en vous en tant que parent ! Pour retrouver plein d’autres conseils RDV sur cette page {URL}. Je vous souhaite une bonne continuation et plein de beaux moments avec votre enfant !'.freeze
    END_SUPPORT_LINK = 'https://magical-bull-428.notion.site/C-est-la-fin-des-SMS-et-des-livres-1001mots-2826d144b6b04e658f4ea090529fb708?pvs=4'.freeze
    INSTAGRAM_SMS = '1001mots vous manque ? Suivez-nous sur Instagram pour plus d’idées d’activités et de conseils : https://www.instagram.com/association_1001mots'.freeze

    def initialize(group_id, end_of_support: true)
      @end_of_support = end_of_support
      @group = Group.find(group_id)
      @children = @end_of_support ? @group.children.where(group_status: 'active') : @group.children.more_than_thirty_five
      @message = @end_of_support ? END_OF_SUPPORT_SMS : MORE_THAN_THIRTY_SIX_SMS
      @link_id = RedirectionTarget.joins(:medium).where(media: { url: END_SUPPORT_LINK }).first&.id
      @errors = []
    end

    def call
      send_end_of_support_message
      program_instagram_message
      stop_supports
      Rollbar.error(@errors) if @errors.any?
      self
    end

    private

    def send_end_of_support_message
      return if @children.count.zero?

      program_message(@children, @message)
    end

    def program_instagram_message
      return unless @end_of_support

      child_ids = @children.months_lt(35).map { |child| "child.#{child.id}" }
      service = ProgramMessageService.new(
        Time.zone.today.advance(months: 1).strftime('%d-%m-%Y'),
        '12:30', child_ids, INSTAGRAM_SMS, nil, nil, false, nil, nil, %w[active waiting]
      ).call
      @errors += service.errors if service.errors.any?
    end

    def stop_supports
      @children.each { |child| child.update(group_status: 'stopped', group_end: Time.zone.today) }
    end

    def sms_count(message, children_count)
      sms_to_send_count = 0
      sms_to_send_count += (message.gsub('{URL}', 'https://app.1001mots.org/r/xxxxxx/xx').size / 160) + 1
      sms_to_send_count *= @children.parents.count # account for potential parent 2
      sms_to_send_count
    end

    def program_message(children, message, date: Time.zone.today, link_id: @link_id, hour: '12:30')
      service = Child::StopSupportMessageService.new(date, hour, children.map { |child| "child.#{child.id}" }, message, nil, link_id).call
      @errors += service.errors if service.errors.any?
    end
  end
end
