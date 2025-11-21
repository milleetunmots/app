# == Schema Information
#
# Table name: children_support_modules
#
#  id                            :bigint           not null, primary key
#  available_support_module_list :string           is an Array
#  book_condition                :string
#  choice_date                   :date
#  is_completed                  :boolean          default(FALSE)
#  is_programmed                 :boolean          default(FALSE), not null
#  module_index                  :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  book_id                       :bigint
#  child_id                      :bigint
#  parent_id                     :bigint
#  support_module_id             :bigint
#
# Indexes
#
#  index_children_support_modules_on_book_id            (book_id)
#  index_children_support_modules_on_child_id           (child_id)
#  index_children_support_modules_on_parent_id          (parent_id)
#  index_children_support_modules_on_support_module_id  (support_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)
#
class ChildrenSupportModule < ApplicationRecord

  CONDITIONS = %w[not_received damaged].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child
  belongs_to :parent
  belongs_to :support_module, optional: true
  belongs_to :book, optional: true

  scope :not_programmed, -> { where(is_programmed: false) }
  scope :programmed, -> { where(is_programmed: true) }
  scope :with_support_module, -> { joins(:support_module) }
  scope :with_the_choice_to_make_by_us, -> { joins(:child).where(child: { group_status: 'active' }).where(support_module: nil).where(is_completed: true) }
  scope :without_choice, -> { joins(:child).where(child: { group_status: 'active' }).where(support_module: nil).where(is_completed: false) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :using_support_module, ->(support_module_id) { where('available_support_module_list::text[] @> ARRAY[?]::text[]', [support_module_id]) }
  scope :with_books, -> { where.not(book_id: nil) }

  validate :support_module_not_programmed, on: :create
  validate :valid_child_parent
  validates :book_condition, inclusion: { in: CONDITIONS }, allow_blank: true

  delegate :group_name,
           to: :child,
           prefix: true,
           allow_nil: true

  delegate  :book_title,
            :book_ean,
            :book_id,
            to: :support_module,
            prefix: true,
            allow_nil: true

  delegate  :title,
            :ean,
            :id,
            to: :book,
            prefix: true,
            allow_nil: true

  after_update :select_for_the_other_parent
  after_update :select_for_siblings
  before_create :set_module_index
  after_save :save_chosen_module_to_child_support, if: :saved_change_to_support_module_id?

  def name
    return support_module.decorate.name_with_tags if support_module
    return 'Laisse le choix à 1001mots' if is_completed

    'Pas encore choisi'
  end

  def available_support_modules
    return [] if available_support_module_list.blank?

    SupportModule.find(available_support_module_list.reject(&:blank?))
  end

  # called in ActiveAdmin form
  # returns the list of available support modules for the child (and bilingualism modules if relevant)
  def available_support_module_collection
    available_support_modules.sort_by { |e| available_support_module_list.index(e[1]) || Float::INFINITY }
    modules = available_support_modules.map(&:decorate).map { |sm| [sm.name_with_tags, sm.id.to_s] }
    return modules unless child.present?

    # Add bilingualism module for the child's age range
    modules + SupportModule.where(theme: SupportModule::BILINGUALISM, age_ranges: [child_age_range(child.months)]).map(&:decorate).map { |sm| [sm.name_with_tags, sm.id.to_s] }
  end

  def support_module_not_programmed
    return unless ChildrenSupportModule.exists?(child: child, parent: parent, is_programmed: false)

    errors.add(:base, :invalid, message: "Un module choisi par le parent pour cet enfant n'a pas encore été programmé")
  end

  def valid_child_parent
    errors.add(:base, :invalid, message: "Cet enfant n'appartient pas à ce parent") unless parent.children.to_a.include? child
  end

  def self.group_id_in(*ids)
    includes(child: :group).where(child: { group_id: ids }).references(:child)
  end

  def select_for_the_other_parent
    the_other_parent = parent == child.parent1 ? child.parent2 : child.parent1

    return if the_other_parent.nil?
    return unless the_other_parent.children_support_modules.where(child_id: child.id).count == 2
    return if child.child_support.call2_status == 'KO' || 'Incomplet / Pas de choix de module'

    the_other_parent.children_support_modules.where(child_id: child.id).latest_first.first.update_columns(
      is_completed: is_completed,
      choice_date: choice_date,
      is_programmed: is_programmed,
      available_support_module_list: available_support_module_list,
      support_module_id: support_module_id
    )
  end

  def select_for_siblings
    return unless saved_change_to_support_module_id?
    return if support_module.nil?
    return unless child.have_siblings_on_same_group?
    return unless child.current_child?

    theme = support_module.theme
    child.siblings_on_same_group.each do |sibling|
      next if child == sibling

      sibling_age = child_age_range(sibling.months)
      sibling_support_module = find_sibling_support_module(sibling.id, sibling_age, parent_id, support_module.for_bilingual, theme: theme) || find_sibling_support_module(sibling.id, sibling_age, parent_id, support_module.for_bilingual)
      find_or_create_children_support_module(sibling.id, sibling_support_module)
    end
  end

  def self.ransackable_scopes(auth_object = nil)
    super + %i[group_id_in]
  end

  def self.chosen_modules_for_group(group_ids = nil, is_programmed = false)
    # return children_support_modules with a module, from children of the group(s) passed as parameter
    # we keep csm of parent1 only
    # we don't retrieve modules of families that cannot receive books at the address they gave us
    modules = includes(child: :child_support).references(:child).with_support_module
    modules = modules.where(is_programmed: is_programmed)
    modules = modules.where(children: { group_id: group_ids }) if group_ids.present?
    modules = modules.where(child_support: { address_suspected_invalid_at: nil } )

    modules.select { |csm| csm.parent_id == csm.child.parent1_id }
  end

  def self.group_active
    includes(child: :group).where(children: { group: Group.group_active })
  end

  def self.group_ended
    includes(child: :group).where(children: { group: Group.group_ended })
  end

  def self.group_next
    includes(child: :group).where(children: { group: Group.group_next })
  end

  ransacker :children_support_module_group_status, formatter: proc { |values|
    values = Array(values)
    ids = []
    ids += group_active.pluck(:id) if values.include?('active')
    ids += group_ended.pluck(:id) if values.include?('ended')
    ids += group_next.pluck(:id) if values.include?('next')
    ids.uniq.presence
  } do |child_support|
    child_support.table[:id]
  end

  private

  def child_age_range(months)
    case months
    when 4..11
      SupportModule::FOUR_TO_ELEVEN
    when 12..17
      SupportModule::TWELVE_TO_SEVENTEEN
    when 18..23
      SupportModule::EIGHTEEN_TO_TWENTY_THREE
    when 24..29
      SupportModule::TWENTY_FOUR_TO_TWENTY_NINE
    when 30..35
      SupportModule::THIRTY_TO_THIRTY_FIVE
    when 36..40
      SupportModule::THIRTY_SIX_TO_FORTY
    when 41..44
      SupportModule::FORTY_ONE_TO_FORTY_FOUR
    end
  end

  def find_sibling_support_module(sibling_id, age, parent_id, for_bilingual, theme: nil)
    support_modules = SupportModule.by_theme
    support_modules = theme.nil? ? support_modules.where("'#{age}' = ANY(age_ranges)") : support_modules.where("'#{age}' = ANY(age_ranges) AND theme = '#{theme}'")
    support_modules = support_modules.where(for_bilingual: for_bilingual) if for_bilingual == false
    support_modules = support_modules.where.not(id: ChildrenSupportModule.where(child_id: sibling_id, parent_id: parent_id, is_programmed: true).pluck(:support_module_id))

    # try to not redo the same theme if possible
    support_modules.select {|sm| !sm.theme.in?(ChildrenSupportModule.with_support_module.where(child_id: sibling_id, parent_id: parent_id, is_programmed: true).map(&:support_module).map(&:theme)) }.first || support_modules.first
  end

  def find_or_create_children_support_module(sibling_id, sibling_support_module)
    sibling_children_support_module = ChildrenSupportModule.find_or_create_by(
      child_id: sibling_id,
      parent_id: parent_id,
      is_programmed: false
    )
    sibling_children_support_module.update(
      available_support_module_list: available_support_module_list,
      support_module: sibling_support_module,
      choice_date: choice_date,
      is_completed: is_completed
    )
  end

  def set_module_index
    return unless child&.group.present? && self.module_index.blank?

    next_module_index = child.group.support_module_programmed + 1
    self.module_index = next_module_index
  end

  def save_chosen_module_to_child_support
    return unless saved_change_to_support_module_id? && support_module.present?
    return unless child.current_child? && child.group
    return if is_programmed || !is_completed

    # Handle groups with no module 0
    # To retrieve the module number (which can be different from module_index because of Module 0)
    # ie. In new groups, Module 0 == module_index 1 // Module 1 == module_index 1 in previous groups w/o Module 0
    current_choice_module_number =
      if child.group.started_at < DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
        module_index
      else
        module_index.to_i - 1
      end
    # we don't care about module 0 & 1 choices, and we don't handle modules after the fifth for now
    return if current_choice_module_number.to_i < 2 || current_choice_module_number.to_i > 6
    return unless parent == child.parent1 || (parent == child.parent2 &&
      ChildrenSupportModule.where(parent: child.parent1, child: child, module_index: module_index, is_completed: true).none?)

    child_support = child.child_support
    child_support.send("module#{current_choice_module_number}_chosen_by_parents=", support_module)
    # avoid unnecessary pop-up trigger in child_support edit form
    child_support.save(touch: false)
  end
end
