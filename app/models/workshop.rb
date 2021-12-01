class Workshop < ApplicationRecord
  include Discard::Model

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :destroy

  def parents_selected
    super&.split(";")
  end

  def parents_selected=(val)
    super(val.reject(&:blank?).join(";"))
  end
end
