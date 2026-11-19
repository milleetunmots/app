class Group

  class StopSupportService

    def initialize(group_id, end_of_support: true)
      @end_of_support = end_of_support
      @group = Group.find(group_id)
      @children = @end_of_support ? @group.children.where(group_status: 'active') : @group.children.more_than_thirty_five
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
      return if @children.none?

      name, key = @end_of_support ? ['Fin du programme', 'fin_programme'] : ["Fin du programme (l'enfant a 3 ans)", 'fin_programme_trois_ans']
      bundle = find_bundle(name: name, key: key)
      return unless bundle

      program_message(@children, bundle.body1, link_id: bundle_redirection_target_id(bundle), rcs_media_id: bundle.rcs_media_id_to_send(1))
    end

    def find_bundle(name:, key:)
      bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
      @errors << "Trio introuvable : « #{name} » (clé #{key}), message non envoyé" unless bundle
      bundle
    end

    def bundle_redirection_target_id(bundle)
      RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
    end

    def program_instagram_message
      return unless @end_of_support

      bundle = find_bundle(name: 'Garder le lien sur Instagram', key: 'instagram_fin_programme')
      return unless bundle

      child_ids = @children.months_lt(35).map { |child| "child.#{child.id}" }
      service = ProgramMessageService.new(
        Time.zone.today.advance(months: 1).strftime('%d-%m-%Y'),
        '12:30', child_ids, bundle.body1, bundle.rcs_media_id_to_send(1), nil, false, nil, nil, %w[active waiting]
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

    def program_message(children, message, link_id:, rcs_media_id:)
      service = Child::StopSupportMessageService.new(
        Time.zone.today, '12:30', children.map { |child| "child.#{child.id}" }, message, rcs_media_id, link_id
      ).call
      @errors += service.errors if service.errors.any?
    end
  end
end
