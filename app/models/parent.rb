# == Schema Information
#
# Table name: parents
#
#  id                    :bigint           not null, primary key
#  address               :string           not null
#  city_name             :string           not null
#  email                 :string
#  first_name            :string           not null
#  gender                :string           not null
#  is_ambassador         :boolean
#  job                   :string
#  last_name             :string           not null
#  letterbox_name        :string
#  phone_number          :string           not null
#  phone_number_national :string
#  postal_code           :string           not null
#  terms_accepted_at     :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_parents_on_address                (address)
#  index_parents_on_city_name              (city_name)
#  index_parents_on_email                  (email)
#  index_parents_on_first_name             (first_name)
#  index_parents_on_gender                 (gender)
#  index_parents_on_is_ambassador          (is_ambassador)
#  index_parents_on_job                    (job)
#  index_parents_on_last_name              (last_name)
#  index_parents_on_phone_number_national  (phone_number_national)
#  index_parents_on_postal_code            (postal_code)
#

class Parent < ApplicationRecord

  GENDERS = %w[m f].freeze
  REGEX_VALID_EMAIL = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :parent1_children,
           class_name: :Child,
           foreign_key: :parent1_id,
           dependent: :nullify

  has_many :parent2_children,
           class_name: :Child,
           foreign_key: :parent2_id,
           dependent: :nullify

  def children
    parent1_children.or(parent2_children)
  end

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  before_validation :format_phone_number

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :letterbox_name, presence: true
  validates :address, presence: true
  validates :city_name, presence: true
  validates :postal_code, presence: true
  validates :phone_number,
            phone: {
              possible: true,
              types: :mobile,
              countries: :fr
            },
            presence: true
  validates :email,
            format: { with: REGEX_VALID_EMAIL, allow_blank: true },
            uniqueness: { case_sensitive: false, allow_blank: true }
  validates :terms_accepted_at, presence: true

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i(first_name last_name phone_number_national email)

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail skip: [:phone_number_national]

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
