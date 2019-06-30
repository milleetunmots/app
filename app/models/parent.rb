class Parent < ApplicationRecord

  GENDERS = %w[m f]
  REGEX_VALID_EMAIL = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  before_validation :format_phone_number

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :address, presence: true
  validates :city_name, presence: true
  validates :postal_code, presence: true
  validates :phone_number,
            phone: {
              possible: true,
              types: :mobile,
              countries: :fr
            },
            presence: true,
            uniqueness: true
  validates :email,
            presence: true,
            format: { with: REGEX_VALID_EMAIL },
            uniqueness: { case_sensitive: false }

  def children
    Child.where(parent1: self).or(Child.where(parent2: self))
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i(first_name last_name phone_number_national email)

  private

  def format_phone_number
    # format phone number to e164
    if attribute_present?('phone_number')
      phone = Phonelib.parse(phone_number)
      self.phone_number = phone.e164
      self.phone_number_national = phone.national(false)
    end
  end
end
