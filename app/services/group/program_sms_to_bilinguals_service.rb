class Group

  class ProgramSmsToBilingualsService

    BUNDLES = {
      bilingues_j0: ['Messages aux familles bilingues (J0)', 0],
      bilingues_j7: ['Messages aux familles bilingues (J+7)', 7],
      bilingues_j14: ['Messages aux familles bilingues (J+14)', 14]
    }.freeze

    def initialize(group_id, first_message_date)
      @group = Group.find(group_id)
      @children = @group.bilingual_children.pluck(:id).map { |id| "child.#{id}" }
      @first_message_date = first_message_date
    end

    def call
      bundles = BUNDLES.to_h { |key, (name, _)| [key, Media::TextMessagesBundle.find_automatic(name: name, key: key)] }
      missing_keys = bundles.select { |_, bundle| bundle.nil? }.keys
      return report_missing(missing_keys) if missing_keys.any?

      bundles.each { |key, bundle| program_message(bundle, date: @first_message_date + BUNDLES[key].last.days) }
      self
    end

    private

    # Tout ou rien : un message bilingue sans les autres n'a pas de sens pour la famille.
    def report_missing(keys)
      Rollbar.error("Group::ProgramSmsToBilingualsService : trio(s) introuvable(s) #{keys.join(', ')}, aucun message programmé", group_id: @group.id)
      self
    end

    def program_message(bundle, date:)
      return if @children.empty?

      link_id = bundle.redirection_target_id(1)
      service = ProgramMessageService.new(date, '12:31', @children, bundle.body1, bundle.rcs_media_id_to_send(1), link_id).call
      raise service.errors.join("\n") if service.errors.any?
    end
  end
end
