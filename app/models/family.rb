# == Schema Information
#
# Table name: families
#
#  id               :bigint           not null, primary key
#  discarded_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  child_support_id :bigint
#  parent1_id       :bigint           not null
#  parent2_id       :bigint
#
# Indexes
#
#  index_families_on_child_support_id  (child_support_id)
#  index_families_on_parent1_id        (parent1_id)
#  index_families_on_parent2_id        (parent2_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent1_id => parents.id)
#  fk_rails_...  (parent2_id => parents.id)
#
class Family < ApplicationRecord

  acts_as_taggable

  after_commit :set_land_tags, on: :create

  belongs_to :parent1, class_name: 'Parent'
  belongs_to :parent2, class_name: 'Parent', optional: true
  belongs_to :child_support, optional: true
  has_many :children

  accepts_nested_attributes_for :parent1
  accepts_nested_attributes_for :parent2
  accepts_nested_attributes_for :child_support

  delegate :email,
           :first_name,
           :last_name,
           :gender,
           :phone_number_national,
           :is_ambassador,
           :is_ambassador?,
           to: :parent1,
           prefix: true

  delegate :email,
           :first_name,
           :last_name,
           :gender,
           :phone_number_national,
           to: :parent2,
           prefix: true,
           allow_nil: true

  delegate :address,
           :city_name,
           :letterbox_name,
           :postal_code,
           to: :parent1

  delegate :is_ambassador,
           :is_ambassador?,
           to: :parent2,
           prefix: true,
           allow_nil: true

  scope :with_support, -> { joins(:child_support) }

  def self.without_support
    left_outer_joins(:child_support).where(child_supports: {id: nil})
  end


  def first_child
      children.order(:id).first
  end

  def parent_events
    Event.where(related_type: "Parent", related_id: [parent1_id, parent2_id].compact)
  end

  def self.parent_id_in(*v)
    where(parent1_id: v).or(where(parent2_id: v))
  end

  def self.parent_id_not_in(*v)
    where.not(parent1_id: v).where.not(parent2_id: v)
  end

  def self.without_parent_text_message_since(v)
    parent_id_not_in(
      Events::TextMessage.where(related_type: :Parent).where("occurred_at >= ?", v).pluck("DISTINCT related_id")
    )
  end

  def create_support!(child_support_attributes)
    child_support = ChildSupport.create!(child_support_attributes)
    self.child_support_id = child_support.id
    save(validate: false)
  end

  def set_land_tags
    tag_list.add("Paris_18_eme") if postal_code.to_i == 75018
    tag_list.add("Paris_20_eme") if postal_code.to_i == 75020
    tag_list.add("Plaisir") if [78370, 78340, 78310, 78990, 78280, 78114, 78320, 78450, 78960, 78100, 78640, 78850].include? postal_code.to_i
    tag_list.add("Trappes") if [78190, 78180, 78280, 78310, 78610, 78960].include? postal_code.to_i
    tag_list.add("Les Clayes Sous Bois") if postal_code.to_i == 78340
    tag_list.add("Coignière, Maurepas") if postal_code.to_i == 78310
    tag_list.add("Elancourt") if postal_code.to_i == 78990
    tag_list.add("Guyancourt") if postal_code.to_i == 78280
    tag_list.add("Montigny le bretonneux") if postal_code.to_i == 78180
    tag_list.add("La verrière") if postal_code.to_i == 78320
    tag_list.add("Villepreux") if postal_code.to_i == 78450
    tag_list.add("Voisin le Bretonneux") if postal_code.to_i == 78960
    tag_list.add("Aulnay-Sous-Bois") if postal_code.to_i == 93600
    tag_list.add("Orleans") if [45000, 45100, 45140, 45160, 45240, 45380, 45400, 45430, 45470, 45650, 45770, 45800].include? postal_code.to_i
    tag_list.add("Montargis") if [45110, 45120, 45200, 45210, 45220, 45230, 45260, 45270, 45290, 45320, 45490, 45500, 45520, 45680, 45700, 49800, 77460, 77570].include? postal_code.to_i
  end
end
