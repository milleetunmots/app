# class Workshop < ApplicationRecord
#   include Discard::Model
#
#   belongs_to :animator, class_name: "AdminUser"
#   has_many :events, dependent: :delete_all
#
#   validates :title,
#     presence: true,
#     uniqueness: {case_sensitive: false}
#
#   validates :animator,
#     presence: true
#   validates :occurred_at,
#     presence: true
#   validates :address,
#     presence: true
#   validates :postal_code,
#     presence: true
#   validates :city_name,
#     presence: true
#
#   validates :co_animator,
#     inclusion: {
#       in: AdminUser.order(:name).pluck(:name),
#       allow_blank: true
#     }
#
#   def parents_selected
#     super&.split(";")
#   end
#
#   def parents_selected=(val)
#     super(val.reject(&:blank?).join(";"))
#   end
# end
