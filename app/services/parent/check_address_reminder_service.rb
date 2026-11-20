require 'csv'

class Parent::CheckAddressReminderService

  attr_reader :errors

  def initialize
    @errors = []
    @date = Time.zone.now
  end

  def call
    ChildSupport.joins(:children).where.not(address_suspected_invalid_at: nil).where(children: { group_status: 'active' }).find_each do |child_support|
      parent = child_support.parent1
      next if parent.book_delivery_location_different_from_home?
      next if Events::TextMessage.automatic_message_sent?(parent: parent, key: Parent::CheckAddressService::KEY, since: 6.days.ago)

      send_verification_message(parent)
    end
    self
  end

  private

  def send_verification_message(parent)
    return report_missing_bundle unless bundle

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{parent.id}"],
      bundle.body1.dup,
      bundle.rcs_media_id_to_send(1),
      link_id,
      automatic_message_key: Parent::CheckAddressService::KEY
    ).call
    @errors << "Address Verification message reminder not sent to #{parent.first_name} #{parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end

  # Cherché au premier parent à relancer, une seule fois.
  def bundle
    return @bundle if defined?(@bundle)

    @bundle = Media::TextMessagesBundle.find_automatic(name: Parent::CheckAddressService::NAME, key: Parent::CheckAddressService::KEY)
  end

  def link_id
    RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
  end

  def report_missing_bundle
    return if @missing_bundle_reported

    @missing_bundle_reported = true
    @errors << "Trio introuvable : « #{Parent::CheckAddressService::NAME} » (clé #{Parent::CheckAddressService::KEY}), message non envoyé"
  end
end
