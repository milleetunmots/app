# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    if user.admin?
      can :manage, :all
      return
    end

    can :manage, [Child, Task]
    can :read, ActiveAdmin::Page, name: 'Dashboard'
    can :update, AdminUser, id: user.id

    if user.team_member?
      can :manage, [Medium, SupportModule, MediaFolder, FieldComment, Tag, Event]
      can [:read, :update], [Group, Parent]
      can :read, [RedirectionUrl, ChildSupport]
    else
      can :manage, [Parent, ChildSupport]
      can :read, [Group, Medium, RedirectionUrl, Tag, Event, SupportModule, MediaFolder, FieldComment]
    end
  end
end
