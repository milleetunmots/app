class Parent::SendPartnerBookAddressVerificationService

  NAME = "Vérification de l'adresse pour le livre offert par un partenaire".freeze
  KEY = 'verification_adresse_livre_partenaire'.freeze

  attr_reader :errors

  def initialize(child_ids:, admin_user:)
    @parent_ids = Child.where(id: child_ids).map { |child| "parent.#{child.parent1_id}" }.uniq
    @admin_user = admin_user
    @errors = []
  end

  def call
    bundle = Media::TextMessagesBundle.find_automatic(name: NAME, key: KEY)
    return report_missing_bundle unless bundle

    link_id = RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
    service = ProgramMessageService.new(
      Time.zone.today, Time.zone.now.strftime('%H:%M'), @parent_ids, bundle.body1, bundle.rcs_media_id_to_send(1), link_id,
      false, nil, nil, Child::GROUP_STATUS, acting_admin_user: @admin_user
    ).call
    @errors.concat(service.errors)
    self
  end

  private

  # Le quota prime : il est réservé puis rendu, pour n'afficher le trio manquant que sous le plafond.
  def report_missing_bundle
    quota_guard = SmsSendRecord::QuotaGuard.new(@admin_user, @parent_ids.size)
    unless quota_guard.reserve!
      @errors << quota_guard.error_message
      return self
    end

    quota_guard.mark_blocked!
    message = "Trio introuvable : « #{NAME} » (clé #{KEY}), message non envoyé"
    Rollbar.error(message)
    @errors << message
    self
  end
end
