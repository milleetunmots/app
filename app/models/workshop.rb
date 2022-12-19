# == Schema Information
#
# Table name: workshops
#
#  id                 :bigint           not null, primary key
#  address            :string           not null
#  city_name          :string           not null
#  co_animator        :string
#  discarded_at       :datetime
#  invitation_message :text             not null
#  name               :string
#  postal_code        :string           not null
#  topic              :string           not null
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

  TOPICS = %w[meal sleep nursery_rhymes books games outside bath emotion]

  belongs_to :animator, class_name: "AdminUser"
  has_one :event, dependent: :destroy
  has_and_belongs_to_many :parents

  before_validation :set_name, on: :create
  after_create :set_workshop_participation

  validates :topic, inclusion: { in: TOPICS, allow_blank: true }
  validates :animator, presence: true
  validates :workshop_date, presence: true
  validates :workshop_date, date: { after: proc { Date.today } }, on: :create
  validates :address, presence: true
  validates :postal_code, presence: true
  validates :city_name, presence: true
  validates :invitation_message, presence: true
  validates :workshop_land, inclusion: { in: Child::LANDS, allow_blank: true }

  def set_name
    self.name = "#{workshop_date.month}/#{workshop_date.year}"
    self.name = workshop_land ? "Atelier du #{name} à #{workshop_land}" : "Atelier du #{name}"
  end

  def set_workshop_participation
    land_parents = if workshop_land == "Paris 18 eme"
                     Parent.where(postal_code: Parent::PARIS_18_EME_POSTAL_CODE)
                   elsif workshop_land == "Paris 20 eme"
                     Parent.where(postal_code: Parent::PARIS_20_EME_POSTAL_CODE)
                   elsif workshop_land == "Plaisir"
                     Parent.where(postal_code: Parent::PLAISIR_POSTAL_CODE)
                   elsif workshop_land == "Trappes"
                     Parent.where(postal_code: Parent::TRAPPES_POSTAL_CODE)
                   elsif workshop_land == "Aulnay sous bois"
                     Parent.where(postal_code: Parent::AULNAY_SOUS_BOIS_POSTAL_CODE)
                   elsif workshop_land == "Orleans"
                     Parent.where(postal_code: Parent::ORELANS_POSTAL_CODE)
                   elsif workshop_land == "Montargis"
                     Parent.where(postal_code: Parent::MONTARGIS_POSTAL_CODE)
                   end

    if land_parents
      land_parents.each do |parent|
        next unless parent.available_for_workshops?

        next unless parent.should_be_contacted?

        next unless parent.target_parent?

        parents << parent
      end
    end

    parents.each do |parent|
      Event.create(
        type: "Events::WorkshopParticipation",
        related: parent,
        body: name,
        occurred_at: workshop_date,
        workshop: self
      )

      response_link = Rails.application.routes.url_helpers.edit_workshop_participation_url(
        parent_id: parent.id,
        workshop_id: id
      )

      message = "#{invitation_message} Pour vous inscrire ou dire que vous ne venez pas, cliquer sur ce lien: #{response_link}"

      SpotHit::SendSmsService.new(
        parent.id,
        DateTime.current.middle_of_day,
        message
      ).call
    end
  end
end
