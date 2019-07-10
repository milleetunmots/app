class Child < ApplicationRecord

  GENDERS = %w[m f]

  belongs_to :child_support, optional: true
  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true

  # ---------------------------------------------------------------------------
  # other relations
  # ---------------------------------------------------------------------------

  # we do not call this 'siblings' because real siblings may have only
  # one parent in common
  def strict_siblings
    self.class.where(parent1_id: parent1_id, parent2_id: parent2_id).where.not(id: id)
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  # computes an (integer) number of months old
  def months
    diff = Time.zone.today.month + Time.zone.today.year * 12 - (birthdate.month + birthdate.year * 12)
    if Time.zone.today.day < birthdate.day
      diff - 1
    else
      diff
    end
  end

  # ---------------------------------------------------------------------------
  # support
  # ---------------------------------------------------------------------------

  def create_support!
    # 1- create support
    child_support = ChildSupport.create!

    # 2- use it on current child
    self.child_support_id = child_support.id
    self.save(validate: false)

    # 3- also update all strict siblings
    # nb: we do this one by one to trigger paper_trail
    strict_siblings.without_support.each do |child|
      child.child_support_id = child_support.id
      child.save(validate: false)
    end
  end

  # ---------------------------------------------------------------------------
  # search by age (in months)
  # ---------------------------------------------------------------------------

  def self.months_gteq(x)
    # >= x months
    # means a birthdate at the most equal to x months ago
    where('birthdate <= ?', Time.zone.today - x.to_i.months)
  end

  def self.months_lt(x)
    # < x months
    # means being at most 1 day less than x months old
    # which means a birthdate strictly greater than exactly x months ago
    where('birthdate > ?', Time.zone.today - x.to_i.months)
  end

  def self.months_equals(x)
    months_gteq(x).merge(months_lt(x.to_i + 1))
  end

  def self.months_between(x, y)
    months_gteq(x).merge(months_lt(y))
  end

  def self.months_between_0_and_3
    months_between(0, 3)
  end

  def self.months_between_3_and_6
    months_between(3, 6)
  end

  def self.months_between_6_and_12
    months_between(6, 12)
  end

  def self.months_between_12_and_18
    months_between(12, 18)
  end

  def self.months_between_18_and_24
    months_between(18, 24)
  end

  def self.months_more_than_24
    months_gteq(24)
  end

  def self.ransackable_scopes(auth_object = nil)
    %i(months_equals months_gteq months_lt)
  end

  # ---------------------------------------------------------------------------
  # other scopes
  # ---------------------------------------------------------------------------

  def self.with_support
    joins(:child_support)
  end

  def self.without_support
    left_outer_joins(:child_support).where(child_supports: {id: nil})
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i(first_name last_name)

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
