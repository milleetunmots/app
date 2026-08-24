class ProgramMessageService

  TYPEFORM_URL_REGEX = %r{https://form.typeform.com/[^\s]*#st=[^\s]+}.freeze
  VIDEOASK_URL_REGEX = %r{https://www\.videoask\.com/[^\s]*#st=[^\s]+}.freeze

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, rcs_media_id = nil, redirection_target_id = nil, quit_message = false, workshop_id = nil, supporter = nil, group_status = ['active'], provider = 'spothit', aircall_number_id = nil, blocked_send_attempt: nil, acting_admin_user: nil)
    @replay_params = {
      planned_date: planned_date,
      planned_hour: planned_hour,
      recipients: (recipients || []).dup,
      message: message.dup,
      rcs_media_id: rcs_media_id,
      redirection_target_id: redirection_target_id,
      quit_message: quit_message,
      workshop_id: workshop_id,
      supporter: supporter,
      group_status: group_status,
      provider: provider,
      aircall_number_id: aircall_number_id
    }
    @blocked_send_attempt_id = blocked_send_attempt&.id
    @planned_timestamp = ActiveSupport::TimeZone['Europe/Paris'].parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @rcs_media_id = rcs_media_id
    @tag_ids = []
    @parent_ids = []
    @redirection_target = RedirectionTarget.find(redirection_target_id) if redirection_target_id
    @group_ids = []
    @recipient_data = []
    @variables = []
    @child_ids = []
    @quit_message = quit_message
    @workshop_id = workshop_id
    @event_params = {}
    @invalid_parent_ids = []
    @supporter_id = supporter.nil? ? nil : supporter.to_i
    @group_status = group_status
    @provider = provider
    @aircall_number_id = aircall_number_id
    @errors = []
    # AdminUser à l'origine de l'envoi, transmis uniquement par les envois
    # manuels (formulaire Message, batch actions, atelier) : c'est lui que le
    # quota anti-fraude décompte. Les envois automatiques ne le passent pas et
    # ne sont donc ni limités ni décomptés. Volontairement absent de
    # @replay_params : la relance d'un envoi bloqué est une action super_admin,
    # donc exemptée par nature.
    @acting_admin_user = acting_admin_user
    @quota_exceeded = false
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?

    find_form_url(TYPEFORM_URL_REGEX)
    find_form_url(VIDEOASK_URL_REGEX)
    get_all_variables if @message.match(/\{(.*?)\}/)
    return self if @errors.any?

    sort_recipients
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    find_parent_ids_from_children
    filter_by_supporter
    filter_by_group_status
    verify_parent_and_children_validity

    return self if @errors.any?

    @errors << 'Aucun parent à contacter.' and return self if @parent_ids.empty?

    @message += ' {URL}' if @redirection_target && !@variables.include?('URL')
    format_data_for_provider
    parent = Parent.kept.where(id: @parent_ids).first
    @errors << "Aucun parent trouvé pour les identifiants suivants : #{@parent_ids}" unless parent
    return self if @errors.any?

    case @provider
    when 'aircall'
      if @message.length > 1600
        @errors << 'Votre message dépasse la limite de 1600 caractères autorisée par Aircall. Veuillez le raccourcir avant de le renvoyer.'
        return self
      end
      guard = BlockedSendAttempt::SendGuard.new(@message, provider: 'aircall', replay_params: @replay_params, blocked_send_attempt_id: @blocked_send_attempt_id)
      if guard.blocked?
        attempts = guard.register!
        # En surveillance, le job réexécute le guard côté service : on lui
        # transmet une des tentatives déjà tracées, la déduplication de
        # BaseSendGuard#register! couvre l'autre kind le cas échéant.
        @blocked_send_attempt_id ||= Array(attempts).first&.id
        if guard.block_send?
          @errors << guard.error_message
          return self
        end
      end
      increment_suggested_videos_counters
      event = Event.create(
        {
          related_id: parent.id,
          related_type: 'Parent',
          body: @message,
          type: 'Events::TextMessage',
          occurred_at: Time.at(@planned_timestamp),
          message_provider: 'aircall'
        }
      )
      Aircall::SendMessageJob.set(wait_until: @planned_timestamp).perform_later(@aircall_number_id, parent&.phone_number, @message, event.id, @replay_params, @blocked_send_attempt_id)
      @errors << "Erreur lors de la création de l'event d'envoi de message pour #{parent.phone_number}." if event.errors.any?
    when 'spothit'
      # Garde anti-fraude : le quota est réservé avant tout appel au provider, sur
      # le nombre de destinataires réellement transmis à Spot-Hit. Placée ici, la
      # garde couvre les trois routes (RCS avec média, RCS basic, SMS) : un
      # message de moins de 160 octets part en RCS basic et échapperait au
      # plafond si seul le chemin SMS était gardé.
      quota_guard = SmsSendRecord::QuotaGuard.new(@acting_admin_user, spot_hit_recipients_count)
      @quota_exceeded = !quota_guard.reserve!
      @errors << quota_guard.error_message and return self if @quota_exceeded

      service =
        if @rcs_media_id.present?
          SpotHit::SendRcsService.new(
            recipients: @recipient_data,
            planned_timestamp: @planned_timestamp,
            media_id: @rcs_media_id,
            fallback_message: @message,
            workshop_id: @workshop_id,
            event_params: @event_params,
            replay_params: @replay_params,
            blocked_send_attempt_id: @blocked_send_attempt_id
          ).call
        elsif basic_rcs?
          SpotHit::SendRcsService.new(
            recipients: @recipient_data,
            planned_timestamp: @planned_timestamp,
            fallback_message: @message,
            basic: true,
            workshop_id: @workshop_id,
            event_params: @event_params,
            replay_params: @replay_params,
            blocked_send_attempt_id: @blocked_send_attempt_id
          ).call
        else
          SpotHit::SendSmsService.new(
            @recipient_data,
            @planned_timestamp,
            @message,
            workshop_id: @workshop_id,
            event_params: @event_params,
            replay_params: @replay_params,
            blocked_send_attempt_id: @blocked_send_attempt_id
          ).call
        end
      increment_suggested_videos_counters if service.errors.empty?
      if service.errors.any?
        # Rien n'est parti (erreur API Spot-Hit ou message bloqué par le
        # BlockedSendAttempt::SendGuard) : le quota réservé est rendu.
        quota_guard.mark_blocked!
        @errors = service.errors
      elsif @invalid_parent_ids.any?
        invalid_parents = Parent.includes(:parent1_children, :parent2_children).where(id: @invalid_parent_ids)
        description_text = "Le message \"#{@message}\" n'a pas été envoyé aux parents pour les raisons suivantes :"
        invalid_parents.each do |parent|
          if parent.valid?
            parent.children.each do |child|
              unless child.valid?
                @errors << "Message non envoyé à #{parent.decorate.name} parce que son enfant #{child.decorate.name} n'est pas valide"
                description_text << "<br>#{ActionController::Base.helpers.link_to(child.decorate.name, Rails.application.routes.url_helpers.edit_admin_child_url(id: child.id), target: '_blank')} : #{child.errors.messages.to_json}"
              end
            end
          else
            @errors << "Message non envoyé à #{parent.decorate.name} parce qu'il n'est pas valide"
            description_text << "<br>#{ActionController::Base.helpers.link_to(parent.decorate.name, Rails.application.routes.url_helpers.edit_admin_parent_url(id: parent.id), target: '_blank')} : #{parent.errors.messages.to_json}"
          end
        end
        Task::CreateAutomaticTaskService.new(
          title: 'Message non envoyé à des parents',
          description: description_text
        ).call
      end
    else
      @errors << "Provider inconnu : #{@provider}" and return self if service.blank?
    end
    self
  end

  # Permet aux appelants qui doivent annuler autre chose (création d'atelier) de
  # distinguer un blocage de quota d'une erreur d'envoi ordinaire — `errors` peut
  # être non vide alors que le message est bien parti.
  def quota_exceeded?
    @quota_exceeded
  end

  protected

  def find_form_url(regex)
    link = @message.scan(regex).first
    return unless link

    @message.gsub!(/#st=[^\s]+/, '#st={PARENT_SECURITY_TOKEN}')
  end

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq
    @errors << 'Veuillez choisir un lien cible.' if @redirection_target.nil? && @variables.include?('URL')
  end

  # Incrémente après le guard d'URLs / l'appel provider, jamais pendant le
  # formatage : un envoi bloqué puis relancé compterait double. En cas d'erreur
  # provider on préfère sous-compter que sur-compter.
  def increment_suggested_videos_counters
    Array(@parents_with_redirection).each { |parent| increment_suggested_videos_counter(parent) }
  end

  def increment_suggested_videos_counter(parent)
    return unless @redirection_target.suggested_videos?

    child_support = parent.current_child&.child_support
    return unless child_support

    child_support.suggested_videos_counter << { redirection_target_id: @redirection_target.id, sending_date: Time.zone.now }
    child_support.save(touch: false)
  end

  # Un message SpotHit sans média part en RCS basic s'il tient en 160 octets,
  # sinon en SMS. SpotHit compte en octets UTF-8 (un accent = 2 octets, € = 3,
  # etc.), d'où bytesize plutôt que length.
  def basic_rcs?
    @rcs_media_id.nil? && @message.bytesize <= 160
  end

  def format_data_for_provider
    case @provider
    when 'spothit'
      format_data_for_spot_hit(@rcs_media_id.present? || basic_rcs?)
    when 'aircall'
      format_data_for_aircall
    else
      @errors << "Provider inconnu : #{@provider}"
    end
  end

  def format_data_for_aircall
    # TO DO: handle multiple recipents with Aircall
    if @parent_ids.many?
      @errors << "Un seul destinataire possible lors d'un envoi de message Aircall"
    elsif @redirection_target || @variables.any?
      Parent.where(id: @parent_ids).find_each do |parent|
        child_name = parent.current_child&.first_name || 'votre enfant'
        child_support_id = parent.current_child&.child_support&.id.to_s
        supporter_name = parent.current_child&.child_support&.supporter&.decorate&.first_name
        supporter_aircall_phone_number = parent.current_child&.child_support&.supporter&.aircall_phone_number
        @message.gsub!('{PRENOM_ENFANT}', child_name)
        @message.gsub!('{CHILD_SUPPORT_ID}', child_support_id)
        @message.gsub!('{PRENOM_ACCOMPAGNANTE}', supporter_name)
        @message.gsub!('{NUMERO_AIRCALL_ACCOMPAGNANTE}', supporter_aircall_phone_number)
        if @redirection_target && parent.current_child.present?
          url = redirection_url_for_a_parent(parent)&.decorate&.visit_url
          (@parents_with_redirection ||= []) << parent
          @message.gsub!('{URL}', url)
        end
      end
    end
  end

  def add_recipient_data(parent, variable, value, error = nil)
    return unless @variables.include?(variable)

    @recipient_data[parent.phone_number][variable] = value
    @errors << error if value.blank? && error.present?
  end

  # Unité de décompte du quota : le nombre de destinataires effectivement
  # transmis à Spot-Hit, après tous les filtres (accompagnante, statut de
  # cohorte, validité parent/enfant, exclusion des ateliers) et dédoublonné par
  # numéro de téléphone. La longueur du message est indifférente.
  # Trois formes possibles selon le canal : hash variables => destinataire,
  # tableau de numéros (RCS sans variable), chaîne de numéros séparés par des
  # virgules (SMS sans variable).
  def spot_hit_recipients_count
    case @recipient_data
    when Hash then @recipient_data.size
    when Array then @recipient_data.uniq.size
    when String then @recipient_data.split(', ').uniq.size
    else 0
    end
  end

  def format_data_for_spot_hit(rcs)
    if @redirection_target || @variables.any?
      @recipient_data = {}
      Parent.where(id: @parent_ids).find_each do |parent|
        @recipient_data[parent.phone_number] = {}
        add_recipient_data(parent, 'PRENOM_ENFANT', parent.current_child&.first_name || 'votre enfant')
        add_recipient_data(parent, 'PARENT_SECURITY_TOKEN', parent.security_token)
        add_recipient_data(parent, 'PRENOM_ACCOMPAGNANTE', parent.current_child&.child_support&.supporter&.decorate&.first_name)
        add_recipient_data(parent, 'NUMERO_AIRCALL_ACCOMPAGNANTE', parent.current_child&.child_support&.supporter&.aircall_phone_number)
        add_recipient_data(parent, 'PARENT_ADDRESS', parent.decorate.full_address(', '))
        add_recipient_data(parent, 'CALL0_CALENDLY_LINK', parent.calendly_booking_urls&.dig('call0'), "Le parent #{parent.id} ne dispose pas d'un lien calendly pour prendre un rdv de l'appel 0")
        add_recipient_data(parent, 'CALL1_CALENDLY_LINK', parent.calendly_booking_urls&.dig('call1'), "Le parent #{parent.id} ne dispose pas d'un lien calendly pour prendre un rdv de l'appel 1")
        add_recipient_data(parent, 'CALL2_CALENDLY_LINK', parent.calendly_booking_urls&.dig('call2'), "Le parent #{parent.id} ne dispose pas d'un lien calendly pour prendre un rdv de l'appel 2")
        add_recipient_data(parent, 'CALL3_CALENDLY_LINK', parent.calendly_booking_urls&.dig('call3'), "Le parent #{parent.id} ne dispose pas d'un lien calendly pour prendre un rdv de l'appel 3")
        add_recipient_data(parent,
                           'RDV_CALENDLY_SCHEDULED_AT_HOUR',
                           parent.scheduled_calls&.scheduled&.upcoming&.order(:scheduled_at)&.last&.scheduled_at&.strftime('%H:%M'),
                           "Le parent #{parent.id} ne dispose pas d'un rdv réglementaire")
        add_recipient_data(parent,
                           'RDV_CALENDLY_CANCEL_URL',
                           parent.scheduled_calls&.scheduled&.upcoming&.order(:scheduled_at)&.last&.cancel_url&.to_s,
                           "Le parent #{parent.id} ne dispose pas d'un lien d'annulation de rdv")
        if @redirection_target && parent.current_child.present?
          @recipient_data[parent.phone_number]['URL'] = redirection_url_for_a_parent(parent)&.decorate&.visit_url
          @url = RedirectionUrl.where(redirection_target: @redirection_target, parent: parent).first
          (@parents_with_redirection ||= []) << parent
        end
      end
    else
      @recipient_data = Parent.where(id: @parent_ids).pluck(:phone_number)
      @recipient_data = @recipient_data.join(', ') unless rcs
    end
  end

  def redirection_url_for_a_parent(parent, child_id = nil)
    targeted_child_id = child_id || parent.current_child.id
    redirection_url = parent.redirection_urls.find_by(child_id: targeted_child_id, parent_id: parent.id, redirection_target_id: @redirection_target.id)

    if redirection_url.nil?
      redirection_url = RedirectionUrl.new(
        redirection_target_id: @redirection_target.id,
        parent_id: parent.id,
        child_id: targeted_child_id
      )
      @errors << "Problème(s) avec l'url courte." unless redirection_url.save
    end

    redirection_url
  end

  def check_all_fields_are_present
    @errors << "Les date et heure d'envoi du message sont requises. Veuillez indiquer une date et une heure valide." if @planned_timestamp.blank?
    @errors << 'La liste des destinataires est vide. Ajoutez au moins un destinataire.' if @recipients.empty?
    @errors << 'Un message est requis. Veuillez le compléter.' if @message.empty? && @redirection_target.nil?
    @errors << "L'ID de numéro Aircall est requis" if @aircall_number_id.blank? && @provider == 'aircall'
  end

  def sort_recipients
    @recipients.each do |recipient_id|
      if recipient_id.include? 'parent.'
        @parent_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'tag.'
        @tag_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'group.'
        @group_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'child.'
        @child_ids << recipient_id[/\d+/].to_i
      end
    end
  end

  def find_parent_ids_from_tags
    @tag_ids.each do |tag_id|
      # taggable_id = id of the parent in our case
      taggable_ids = Tagging.by_taggable_type('Parent').by_tag_id(tag_id).pluck(:taggable_id)
      @parent_ids += Parent.where(id: taggable_ids).select(&:should_be_contacted?).pluck(:id)
    end
  end

  def filter_by_supporter
    return unless @supporter_id

    parent1_ids = Parent.joins(parent1_children: :child_support).where(id: @parent_ids).where(child_support: { supporter_id: @supporter_id }).ids
    parent2_ids = Parent.joins(parent2_children: :child_support).where(id: @parent_ids).where(child_support: { supporter_id: @supporter_id }).ids
    @parent_ids = (parent1_ids + parent2_ids).uniq
  end

  def filter_by_group_status
    parent1_ids = Parent.joins(:parent1_children).where(id: @parent_ids).where(parent1_children: { group_status: @group_status }).ids
    parent2_ids = Parent.joins(:parent2_children).where(id: @parent_ids).where(parent2_children: { group_status: @group_status }).ids
    @parent_ids = (parent1_ids + parent2_ids).uniq
  end

  def find_parent_ids_from_groups
    Group.includes(:children).where(id: @group_ids).find_each do |group|
      group.children.each do |child|
        @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
        @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
      end
    end
  end

  def find_parent_ids_from_children
    Child.where(id: @child_ids).find_each do |child|
      @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
      @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
    end
  end

  def verify_parent_and_children_validity
    parents = Parent.includes(:parent1_children, :parent2_children).where(id: @parent_ids)

    parents.each do |parent|
      if parent.valid?
        parent.children.each do |child|
          @invalid_parent_ids << @parent_ids.delete(parent.id) unless child.valid?
        end
      else
        @invalid_parent_ids << @parent_ids.delete(parent.id)
      end
    end
  end
end
