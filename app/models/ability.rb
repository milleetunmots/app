# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank? || user.is_disabled?

    can :read, ActiveAdmin::Page, name: 'Search'
    can :manage, ActiveAdmin::Page, name: 'Volunteer Parent Form'

    case user.user_role
    when 'super_admin'
      can :manage, :all
    when 'contributor'
      can :manage,
          [Parent, Child, ChildSupport, Workshop, Task, SupportModule, MediaFolder, Medium, Tag, Event, Group, Book, ChildrenSupportModule, Source]
      can :read, AdminUser
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :manage, ActiveAdmin::Page, name: 'Module'
      can :manage, ActiveAdmin::Page, name: 'Messages'
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :read, ActiveAdmin::Page, name: 'Dashboard'
    when 'reader'
      can :manage, Task, reporter_id: user.id
      can %i[read update], [Parent, Child, ChildSupport]
      can :read, [Workshop, SupportModule, Group, Book, ChildrenSupportModule, AdminUser, Source]
      can %i[create read update], Tag
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :send_message_to_parent1, ChildSupport
      can :send_message_to_parent2, ChildSupport
    when 'caller'
      can :manage, Task, reporter_id: user.id
      can %i[create read update], Parent do |parent|
        parent.current_child&.child_support&.supporter_id == user.id
      end
      can %i[create read update], Child, child_support: { supporter_id: user.id }
      can %i[create read update], ChildSupport, supporter_id: user.id
      can %i[create read update], ChildrenSupportModule, child: { child_support: { supporter_id: user.id } }
      can :read, SupportModule
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :select_module_for_parent1, ChildSupport, supporter_id: user.id
      can :select_module_for_parent2, ChildSupport, supporter_id: user.id
      can :send_message_to_parent1, ChildSupport, supporter_id: user.id
      can :send_message_to_parent2, ChildSupport, supporter_id: user.id
    when 'animator'
      can :manage, Task, reporter_id: user.id
      can %i[create read update], [Parent, Child, ChildSupport, ChildrenSupportModule]
      can :manage, [Workshop, Event, Source]
      can :read, SupportModule
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :select_module_for_parent1, ChildSupport, supporter_id: user.id
      can :select_module_for_parent2, ChildSupport, supporter_id: user.id
      can :send_message_to_parent1, ChildSupport, supporter_id: user.id
      can :send_message_to_parent2, ChildSupport, supporter_id: user.id
    end
  end

  def can?(action, subject, *extra_args)
    while subject.is_a?(Draper::Decorator)
      subject = subject.model
    end
    super(action, subject, *extra_args)
  end
end
