class Parent::MatchCalendlyInviteeContactService

  # prérempli par « Créer un rdv » quand le parent n'a pas d'e-mail : partagé par beaucoup de RDV
  PLACEHOLDER_EMAIL = 'rdv@1001mots.org'.freeze

  attr_reader :errors, :parent

  def initialize(host_calendly_user_uri:, email:, name:)
    @errors = []
    @host_calendly_user_uri = host_calendly_user_uri
    @email = email
    @name = name
  end

  def call
    find_host
    return self if @errors.any?

    @parent = unique_match { |candidate| matching_email?(candidate) } ||
              unique_match { |candidate| matching_name?(candidate) }
    self
  end

  private

  def find_host
    @host = AdminUser.find_by(calendly_user_uri: @host_calendly_user_uri)
    return if @host

    @errors << {
      message: "Aucune accompagnante n'a ce compte Calendly",
      context: { host_calendly_user_uri: @host_calendly_user_uri }
    }
  end

  def unique_match(&block)
    matches = candidates.select(&block)
    matches.first if matches.one?
  end

  # parents des familles dont l'enfant courant est suivi par l'accompagnante hôte
  def candidates
    @candidates ||= ChildSupport.where(supporter: @host)
                                .includes(:parent1, :parent2)
                                .flat_map { |child_support| [child_support.parent1, child_support.parent2] }
                                .compact
                                .uniq
                                .select { |parent| parent.kept? && parent.current_child&.child_support&.supporter_id == @host.id }
  end

  def matching_email?(candidate)
    invitee_email.present? && candidate.email.to_s.strip.downcase == invitee_email
  end

  def invitee_email
    email = @email.to_s.strip.downcase
    email == PLACEHOLDER_EMAIL ? nil : email
  end

  def matching_name?(candidate)
    invitee_name = normalize_name(@name)
    invitee_name.present? && normalize_name("#{candidate.first_name} #{candidate.last_name}") == invitee_name
  end

  def normalize_name(name)
    I18n.transliterate(name.to_s).strip.downcase
  end
end
