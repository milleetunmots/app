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

  acts_as_taggable

  TOPICS = %w[meal sleep nursery_rhymes books games outside bath emotion]

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :delete_all
  has_many :participants, through: :events, as: :related, source: :related, source_type: :Parent

  accepts_nested_attributes_for :events

  before_validation :set_workshop_participation, :set_workshop_tags_participation, :set_name, on: :create

  validates :topic,
    presence: true,
    inclusion: {in: TOPICS}
  validates :animator,
    presence: true
  validates :workshop_date,
    presence: true
  validates :address,
    presence: true
  validates :postal_code,
    presence: true
  validates :city_name,
    presence: true
  validates :land,
    inclusion: {in: Child::LANDS}
  validates :invitation_message,
    presence: true

  validates_associated :events

  def set_name
    self.name = "#{workshop_date.year}_#{workshop_date.month}"
    self.name = "#{tag_list.join("_")}_#{name}" unless tag_list.empty?
  end

  def set_workshop_participation
    Parent.tagged_with(tag_list.join(", ")).each do |parent|
      events.create(type: "Events::WorkshopParticipation", workshop_id: id, related_id: parent.id, occurred_at: workshop_date)
    end
  end

  def set_workshop_tags_participation
    events.each do |participation|
      participation.occurred_at = workshop_date
      participation.type = "Events::WorkshopParticipation"
      participation.body = name
      participation.save(validate: false)
    end
  end
end
