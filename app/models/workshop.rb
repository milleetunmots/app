# == Schema Information
#
# Table name: workshops
#
#  id                             :bigint           not null, primary key
#  address                        :string           not null
#  address_supplement             :string
#  canceled                       :boolean          default(FALSE), not null
#  city_name                      :string           not null
#  co_animator                    :string
#  discarded_at                   :datetime
#  first_workshop_time_slot       :time             default(Sat, 01 Jan 2000 11:00:00.000000000 CET +01:00), not null
#  invitation_message             :text             not null
#  location                       :string
#  name                           :string
#  postal_code                    :string           not null
#  scheduled_invitation_date_time :datetime
#  second_workshop_time_slot      :time
#  topic                          :string
#  workshop_date                  :date             not null
#  workshop_land                  :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  animator_id                    :bigint           not null
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

  attr_accessor :parent_selection
  attr_reader :invitation_scheduled, :scheduled_invitation_date, :scheduled_invitation_time

  TOPICS = %w[meal sleep nursery_rhymes books games outside bath emotion].freeze

  belongs_to :animator, class_name: 'AdminUser'
  has_many :workshop_participations, class_name: 'Events::WorkshopParticipation', dependent: :destroy
  has_and_belongs_to_many :parents

  before_save :set_name
  before_create :select_recipients
  after_create :send_message
  after_save :update_workshop_participation

  validates :topic, inclusion: { in: TOPICS, allow_blank: true }
  validates :animator, presence: true
  validates :workshop_date, presence: true
  validates :first_workshop_time_slot, presence: true
  validates :location, presence: true
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

  def select_recipients
    @recipients = []
    land_parents.each do |parent|
      next if parent.is_excluded_from_workshop
      next unless parent.available_for_workshops?
      next unless parent.should_be_contacted?
      next unless parent.target_parent?
      if parent.caf93?
        next if 'Eval25 - 3 tentatives'.in?(parent.tag_list) ||
                'Eval25 - impossible'.in?(parent.tag_list) ||
                'Eval25 - refusée'.in?(parent.tag_list)
        next if parent.children.all { |child| child.group_status == 'waiting' }
        next if parent.children.all { |child| child.group_status == 'active' && child.group&.started_at > Time.zone.now } && !'Eval25 - validée'.in?(parent.tag_list)
      end

      @recipients << parent
    end

    (parents.to_a - land_parents.to_a).each do |parent|
      next if parent.is_excluded_from_workshop

      @recipients << parent
    end
  end

  def send_message
    recipients = @recipients.map { |recipient| "parent.#{recipient.id}" }
    date = scheduled_invitation_date_time.nil? ? Time.zone.now : scheduled_invitation_date_time

    message = "#{invitation_message} Pour vous inscrire ou dire que vous ne venez pas, cliquez sur ce lien: {RESPONSE_LINK}"
    service = Workshop::ProgramWorkshopInvitationService.new(date.to_date, date.strftime('%H:%M'), recipients, message, nil, nil, nil, id, nil, %w[waiting active paused stopped disengaged]).call
    Rollbar.error(service.errors) if service.errors.any?
  end

  def update_workshop_participation
    workshop_participations.update_all(occurred_at: workshop_date) if saved_change_to_workshop_date
    workshop_participations.update_all(body: name) if saved_change_to_name
  end

  def land_parents
    Parent.where(postal_code: Child::LANDS[workshop_land])
  end
end
