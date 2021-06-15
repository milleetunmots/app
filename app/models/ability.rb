# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      can :manage, [Child, Task]
      if user.admin?
        can :manage, :all
      elsif user.team_member?
        can :manage, [Medium, Tag, Event]
        can [:read, :update], [Group, Parent]
        can :read, [RedirectionUrl, ChildSupport]
      else
        can :manage, [Parent, ChildSupport]
        can :read, [Group, Medium, RedirectionUrl, Tag, Event]
      end
    end
  end
end
