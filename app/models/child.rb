class Child < ApplicationRecord

  GENDERS = %w[m f]

  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true

  # computes an (integer) number of months old
  def months
    diff = Time.zone.today.month + Time.zone.today.year * 12 - (birthdate.month + birthdate.year * 12)
    if Time.zone.today.day < birthdate.day
      diff - 1
    else
      diff
    end
  end

  # allow to search by age (in months)

  def self.months_gteq(months)
    # >= x months
    # means a birthdate at the most equal to x months ago
    where('birthdate <= ?', Time.zone.today - months.to_i.months)
  end
  def self.months_lt(months)
    # < x months
    # means being at most 1 day less than x months old
    # which means a birthdate strictly greater than exactly x months ago
    where('birthdate > ?', Time.zone.today - months.to_i.months)
  end
  def self.months_equals(months)
    months_gteq(months).merge(months_lt(months.to_i + 1))
  end
  def self.ransackable_scopes(auth_object = nil)
    %i(months_equals months_gteq months_lt)
  end

end
