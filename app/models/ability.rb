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
      can :manage, ActiveAdmin::Page, name: 'Restart Support Form'
      can :read, ActiveAdmin::Page, name: 'Dashboard'
    when 'reader'
      can :autocomplete, [Group, Tag]
      can :create, Task
      can %i[read update destroy], Task, reporter_id: user.id
      can :manage, [Parent, Child, ChildSupport]
      cannot %i[new create destroy discard select_module_for_parent1 select_module_for_parent2 add_child add_parent quit_group], [Parent, Child, ChildSupport]
      cannot :upload_undelivered_books, Parent
      can :read, [Workshop, SupportModule, Group, Book, ChildrenSupportModule, AdminUser, Source]
      can %i[create read update], Tag
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :send_message_to_parent1, ChildSupport
      can :send_message_to_parent2, ChildSupport
      cannot :distribute_child_supports_to_callers, Group
    when 'caller'
      can :autocomplete, [Group, Tag] # we use this custom action to search Groups and Tags for users without read permission (ie. in get_recipients)
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :create, Task
      can %i[read update destroy], Task, reporter_id: user.id
      can :create, Parent
      can %i[read update], Parent, parent1_children: { child_support: { supporter_id: user.id } }
      can %i[read update], Parent, parent2_children: { child_support: { supporter_id: user.id } }
      cannot :upload_undelivered_books, Parent
      can :create, Child
      can %i[read update add_parent add_child], Child, child_support: { supporter_id: user.id }
      can %i[create read update add_parent add_child], ChildSupport, supporter_id: user.id
      can :create, ChildrenSupportModule
      can %i[read update], ChildrenSupportModule, child: { child_support: { supporter_id: user.id } }
      can :read, SupportModule
      can :read, Event, type: 'Events::TextMessage', related_type: 'Parent', related_id: Parent.joins(parent1_children: :child_support).where(child_supports: { supporter_id: user.id }).pluck(:id)
      can :read, Event, type: 'Events::TextMessage', related_type: 'Parent', related_id: Parent.joins(parent2_children: :child_support).where(child_supports: { supporter_id: user.id }).pluck(:id)
      cannot :read, [Events::OtherEvent, Events::WorkshopParticipation, Events::SurveyResponse]
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Restart Support Form'
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :select_module_for_parent1, ChildSupport, supporter_id: user.id
      can :select_module_for_parent2, ChildSupport, supporter_id: user.id
      can :send_message_to_parent1, ChildSupport, supporter_id: user.id
      can :send_message_to_parent2, ChildSupport, supporter_id: user.id
    when 'animator'
      can :autocomplete, [Group, Tag]
      can :create, Task
      can %i[read update destroy], Task, reporter_id: user.id
      can :manage, [Parent, Child, ChildSupport, ChildrenSupportModule]
      cannot %i[destroy discard], [Parent, Child, ChildSupport, ChildrenSupportModule]
      cannot :upload_undelivered_books, Parent
      can :manage, Workshop
      can :manage, Event, type: %w[Events::TextMessage Events::WorkshopParticipation]
      cannot :read, [Events::OtherEvent, Events::SurveyResponse]
      can :read, SupportModule
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Restart Support Form'
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
