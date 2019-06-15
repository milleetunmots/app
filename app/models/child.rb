class Child < ApplicationRecord

  GENDERS = %w[m f]

  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true

end
