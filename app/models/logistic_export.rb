# == Schema Information
#
# Table name: logistic_exports
#
#  id            :bigint           not null, primary key
#  group_modules :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class LogisticExport < ApplicationRecord
  has_one_attached :archive

  validates :group_modules, presence: true
  validate :validate_group_modules_format

  scope :by_group_ids, ->(*group_ids) {
    group_ids = group_ids.flatten
    group_ids = Array(group_ids).map(&:to_i).reject(&:zero?)
    return none if group_ids.empty?

    conditions = group_ids.map { |gid| sanitize_sql(["group_modules @> ?", [{ group_id: gid }].to_json]) }
    where(conditions.join(" OR "))
  }

  def self.ransackable_scopes(_auth_object = nil)
    super + %i[by_group_ids]
  end

  def groups
    Group.where(id: group_modules.map { |gm| gm["group_id"] })
  end

  def group_module_labels
    group_modules.map do |gm|
      group = Group.find_by(id: gm["group_id"])
      group_name = group&.name || "Groupe inconnu"
      "#{group_name} : module #{gm['module_number']}"
    end
  end

  private

  def validate_group_modules_format
    unless group_modules.is_a?(Array) && group_modules.all? { |gm| gm.is_a?(Hash) && gm.key?("group_id") && gm.key?("module_number") }
      errors.add(:group_modules, "doit être un tableau de { group_id, module_number }")
    end
  end
end
