# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    
    if user.is_a?(AdminUser)
      admin_user_abilities(user)
    elsif user.is_a?(ExternalUser)
      external_user_abilities(user)
    end
  end

  def can?(action, subject, *extra_args)
    while subject.is_a?(Draper::Decorator)
      subject = subject.model
    end
    super(action, subject, *extra_args)
  end

  private

  def admin_user_abilities(user)
    return if user.is_disabled?

    if user.admin? || user.logistics_team?
      can :manage, :all
      cannot [:disable, :activate], AdminUser if user.logistics_team?
      return
    end

    can :manage, [Parent, ChildrenSupportModule]
    can :update, AdminUser, id: user.id
    can :read, ActiveAdmin::Page, name: "Dashboard"
    can :read, ActiveAdmin::Page, name: "Search"
    can :manage, ActiveAdmin::Page, name: "Message"
    can :manage, ActiveAdmin::Page, name: "Stop Support Form"
    can :manage, ActiveAdmin::Page, name: "Volunteer Parent Form"


    if user.team_member?
      can :manage, ActiveAdmin::Page, name: "Module"
      can :manage, ActiveAdmin::Page, name: "Messages"
      can :manage, [Medium, SupportModule, MediaFolder, FieldComment, Tag, Event, Child, Workshop, ChildSupport, Task]
      can [:create, :read, :update], [Group, RedirectionUrl]
    else
      can :manage, ChildSupport, supporter_id: user.id
      can :manage, Task, reporter_id: user.id
      cannot :discard, ChildSupport
      can :read, [Group, Medium, RedirectionUrl, Tag, Event, SupportModule, MediaFolder, FieldComment]
      can [:create, :read, :update], Child
    end
  end

  def external_user_abilities(user)
    if user.pmi_admin?
      can :manage, ExternalUser, source_id: user.source_id
      can :read, :toto
    end
    can :read, :dashboard
  end
end
