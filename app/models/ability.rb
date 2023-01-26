# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    if user.admin?
      can :manage, :all
      return
    end

    can :manage, [Task, Parent, ChildrenSupportModule]
    can :update, AdminUser, id: user.id
    can :read, ActiveAdmin::Page, name: "Dashboard"
    can :read, ActiveAdmin::Page, name: "Search"
    can :manage, ActiveAdmin::Page, name: "Message"


    if user.team_member? || user.logistics_team?
      can :manage, ActiveAdmin::Page, name: "Module"
      can :manage, ActiveAdmin::Page, name: "Messages"
      can :manage, [Medium, SupportModule, MediaFolder, FieldComment, Tag, Event, Child, Workshop]
      can [:create, :read, :update], [Group, RedirectionUrl, ChildSupport]
    else
      can :manage, ChildSupport, supporter_id: user.id
      can :read, [Group, Medium, RedirectionUrl, Tag, Event, SupportModule, MediaFolder, FieldComment]
      can [:create, :read, :update], Child
    end
  end

  def can?(action, subject, *extra_args)
    while subject.is_a?(Draper::Decorator)
      subject = subject.model
    end
    super(action, subject, *extra_args)
  end
end
