# == Schema Information
#
# Table name: children_groups
#
#  id         :bigint           not null, primary key
#  quit_at    :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  child_id   :bigint
#  group_id   :bigint
#
# Indexes
#
#  index_children_groups_on_child_id  (child_id)
#  index_children_groups_on_group_id  (group_id)
#  index_children_groups_on_quit_at   (quit_at)
#

class ChildrenGroup < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child
  belongs_to :group

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validate :only_one_current_not_ended_group, on: :create

  def only_one_current_not_ended_group
    if has_not_quit? && self.class.not_quit.for_not_ended_group.where(child: child).any?
      errors.add(:child_id, 'ne peut pas être dans 2 cohortes en même temps')
    end
  end

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :not_quit, -> { where("quit_at IS NULL OR quit_at > ?", Date.today) }
  scope :quit, -> { where("quit_at <= ?", Date.today) }

  scope :for_not_ended_group, -> { where(group: Group.not_ended) }

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def has_quit?
    quit_at && quit_at <= Date.today
  end

  def has_not_quit?
    !has_quit?
  end

  def is_current_not_ended?
    has_not_quit? && group.is_not_ended?
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
