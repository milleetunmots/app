# == Schema Information
#
# Table name: workshops
#
#  id                 :bigint           not null, primary key
#  address            :string           not null
#  canceled           :boolean          default(FALSE), not null
#  city_name          :string           not null
#  co_animator        :string
#  discarded_at       :datetime
#  invitation_message :text             not null
#  location           :string
#  name               :string
#  postal_code        :string           not null
#  topic              :string
#  workshop_date      :date             not null
#  workshop_land      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  animator_id        :bigint           not null
#
# Indexes
#
#  index_workshops_on_animator_id  (animator_id)
#
# Foreign Keys
#
#  fk_rails_...  (animator_id => admin_users.id)
#
class Workshop < ApplicationRecord
  include Discard::Model

  TOPICS = %w[meal sleep nursery_rhymes books games outside bath emotion].freeze

  belongs_to :animator, class_name: 'AdminUser'
  has_many :workshop_participations, class_name: 'Events::WorkshopParticipation', dependent: :destroy
  has_and_belongs_to_many :parents

  before_save :set_name
  before_create :set_workshop_participation
  after_create :send_message
  after_save :update_workshop_participation

  validates :topic, inclusion: { in: TOPICS, allow_blank: true }
  validates :animator, presence: true
  validates :workshop_date, presence: true
  validates :workshop_date, date: { after: proc { Time.zone.today } }, on: :create
  validates :address, presence: true
  validates :postal_code, presence: true
  validates :city_name, presence: true
  validates :invitation_message, presence: true
  validates :workshop_land, inclusion: { in: Child::LANDS, allow_blank: true }

  private

  def set_name
    self.name = "#{workshop_date.day}/#{workshop_date.month}/#{workshop_date.year}"
    self.name = location.nil? ? "Atelier du #{name}" : "Atelier du #{name} à #{location}"
    self.name = "#{name}, avec #{animator.name}"
    self.name = "#{name}, sur le thème \"#{Workshop.human_attribute_name("topic.#{topic}")}\"" if topic.present?
  end

  def set_workshop_participation
    land_parents.each do |parent|
      next if parent.exclude_to_workshop

      next unless parent.available_for_workshops?

      next unless parent.should_be_contacted?

      next unless parent.target_parent?

      workshop_participations.build(
        type: 'Events::WorkshopParticipation',
        related: parent,
        body: name,
        occurred_at: workshop_date
      )
    end

    (parents.to_a - land_parents.to_a).each do |parent|
      next if parent.exclude_to_workshop

      workshop_participations.build(
        type: 'Events::WorkshopParticipation',
        related: parent,
        body: name,
        occurred_at: workshop_date
      )
    end
  end

  def send_message
    recipients = workshop_participations.map { |wp| "parent.#{wp.related_id}" }

    message = "#{invitation_message} Pour vous inscrire ou dire que vous ne venez pas, cliquez sur ce lien: {RESPONSE_LINK}"

    service = Workshop::ProgramWorkshopInvitationService.new(Time.zone.today, Time.zone.now.strftime('%H:%M'), recipients, message, nil, nil, nil, id).call

    Rollbar.error(service.errors) if service.errors.any?
  end

  def update_workshop_participation
    workshop_participations.update_all(occurred_at: workshop_date) if saved_change_to_workshop_date
    workshop_participations.update_all(body: name) if saved_change_to_name
  end

  def land_parents
    postal_codes =  case workshop_land
                    when 'Paris 18 eme'
                      Parent::PARIS_18_EME_POSTAL_CODE
                    when 'Paris 20 eme'
                      Parent::PARIS_20_EME_POSTAL_CODE
                    when 'Plaisir'
                      Parent::PLAISIR_POSTAL_CODE
                    when 'Trappes'
                      Parent::TRAPPES_POSTAL_CODE
                    when 'Aulnay sous bois'
                      Parent::AULNAY_SOUS_BOIS_POSTAL_CODE
                    when 'Orleans'
                      Parent::ORELANS_POSTAL_CODE
                    when 'Montargis'
                      Parent::MONTARGIS_POSTAL_CODE
                    when 'Pithiviers'
                      Parent::PITHIVIERS_POSTAL_CODE
                    when 'Gien'
                      Parent::GIEN_POSTAL_CODE
                    when 'Villeneuve-la-Garenne'
                      Parent::VILLENEUVE_LA_GARENNE_POSTAL_CODE
                    when 'Bondy'
                      Parent::BONDY_POSTAL_CODE
                    when 'Mantes La Jolie'
                      Parent::MANTES_LA_JOLIE_POSTAL_CODE
                    else
                      nil
                    end

    Parent.where(postal_code: postal_codes)
  end
end
