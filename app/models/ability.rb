# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    return if user.is_disabled?

    if user.admin? || user.logistics_team?
      can :manage, :all
      cannot [:disable, :activate], AdminUser if user.logistics_team?
      return
    end

    can :manage, [Task, Parent, ChildrenSupportModule]
    can :update, AdminUser, id: user.id
    can :read, ActiveAdmin::Page, name: "Dashboard"
    can :read, ActiveAdmin::Page, name: "Search"
    can :manage, ActiveAdmin::Page, name: "Message"


    if user.team_member?
      can :manage, ActiveAdmin::Page, name: "Module"
      can :manage, ActiveAdmin::Page, name: "Messages"
      can :manage, [Medium, SupportModule, MediaFolder, FieldComment, Tag, Event, Child, Workshop, ChildSupport]
      can [:create, :read, :update], [Group, RedirectionUrl]
    else
      can :manage, ChildSupport, supporter_id: user.id
      cannot :discard, ChildSupport
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
