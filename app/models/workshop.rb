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
#  land               :string
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

  TOPICS = %w[meal sleep nursery_rhymes books games outside bath emotion]

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :delete_all
  has_many :participants, through: :events, as: :related, source: :related, source_type: :Parent

  accepts_nested_attributes_for :events

  before_validation :set_workshop_participation, on: :create

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

  # before_commit do |workshop|
  #
  # end

  def set_workshop_participation
    self.name = "#{workshop_date.year}_#{workshop_date.month}"
    self.name = "#{tag_list.join("_")}_#{name}" unless tag_list.empty?
    self.name = "#{land}_#{name}" if land

    # Parent.tagged_with(tag_list, any: true).each do |parent|
    #   participation = Event.where(type: "Events::WorkshopParticipation", occurred_at: workshop_date, related: parent, body: name).first_or_create
    #   events << participation unless events.include? participation
    # end

    events.each do |participation|
      participation.occurred_at = workshop_date
      participation.type = "Events::WorkshopParticipation"
      participation.body = name
      participation.save(validate: false)
    end
  end

  acts_as_taggable

end
