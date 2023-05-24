# == Schema Information
#
# Table name: children_support_modules
#
#  id                            :bigint           not null, primary key
#  available_support_module_list :string           is an Array
#  choice_date                   :date
#  is_completed                  :boolean          default(FALSE)
#  is_programmed                 :boolean          default(FALSE), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  child_id                      :bigint
#  parent_id                     :bigint
#  support_module_id             :bigint
#
# Indexes
#
#  index_children_support_modules_on_child_id           (child_id)
#  index_children_support_modules_on_parent_id          (parent_id)
#  index_children_support_modules_on_support_module_id  (support_module_id)
#
class ChildrenSupportModule < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child
  belongs_to :parent
  belongs_to :support_module, optional: true

  scope :not_programmed, -> { where(is_programmed: false) }
  scope :programmed, -> { where(is_programmed: true) }
  scope :with_support_module, -> { joins(:support_module) }
  scope :with_the_choice_to_make_by_us, -> { where(support_module: nil).where(is_completed: true) }
  scope :without_choice, -> { where(support_module: nil).where(is_completed: false) }
  scope :latest_first, -> { order(created_at: :desc) }

  validate :support_module_not_programmed, on: :create
  validate :valid_child_parent

  delegate :group_name,
           to: :child,
           prefix: true,
           allow_nil: true

  after_update :select_for_the_other_parent

  def name
    return support_module.decorate.name_with_tags if support_module
    return "Laisse le choix à 1001mots" if is_completed

    "Pas encore choisi"
  end

  def available_support_modules
    SupportModule.where(id: available_support_module_list)
  end

  def available_support_module_collection
    available_support_modules.sort_by { |e| available_support_module_list.index(e[1]) || Float::INFINITY }
    available_support_modules.decorate.map { |sm| [sm.name_with_tags, sm.id.to_s] }
  end

  def support_module_not_programmed
    if ChildrenSupportModule.exists?(child: child, parent: parent, is_programmed: false)
      errors.add(:base, :invalid, message: "Un module choisi par le parent pour cet enfant n'a pas encore été programmé")
    end
  end

  def valid_child_parent
    errors.add(:base, :invalid, message: "Cet enfant n'appartient pas à ce parent") unless parent.children.to_a.include? child
  end

  def self.group_id_in(*v)
    includes(child: :group).where("children.group_id IN (?)", v).references(:children)
  end

  def select_for_the_other_parent
    the_other_parent = parent == child.parent1 ? child.parent2 : child.parent1

    return if the_other_parent.nil?
    return unless the_other_parent.children_support_modules.where(child_id: child.id).count == 2
    return if child.child_support.call2_status == 'KO'

    the_other_parent.children_support_modules.latest_first.first.update_columns(
      is_completed: is_completed,
      choice_date: choice_date,
      is_programmed: is_programmed,
      available_support_module_list: available_support_module_list,
      support_module_id: support_module_id
    )
  end

  def self.ransackable_scopes(auth_object = nil)
    super + %i[group_id_in]
  end
end
