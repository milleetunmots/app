# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # Droits conservés pendant une simulation de connexion (« Se connecter en tant que »).
  # :edit, :update et :update_sensitive_information n'y sont que pour afficher les formulaires
  # d'édition, que les accompagnantes utilisent comme fiche : l'enregistrement est refusé
  # par ApplicationController#enforce_read_only_impersonation. Les pages ActiveAdmin
  # (ActiveAdmin::Page) gardent leurs droits : leurs actions à effet de bord sont toutes
  # en POST ou DELETE, donc refusées au même endroit.
  IMPERSONATION_ACTIONS = %i[
    read edit update autocomplete read_content
    read_sensitive_information update_sensitive_information
    send_message_to_parent1 send_message_to_parent2
  ].freeze

  # Par défaut, l'Ability suit le contexte de la requête : ActiveAdmin l'instancie lui-même
  # avec le seul utilisateur courant.
  def initialize(user, read_only: Current.impersonating?)
    @read_only = read_only
    return if user.blank? || user.is_disabled?

    can :read, ActiveAdmin::Page, name: 'Search'
    can :manage, ActiveAdmin::Page, name: 'Volunteer Parent Form'

    case user.user_role
    when 'super_admin'
      can :manage, :all
      # Réservée aux accompagnantes : le can :manage, :all ouvrirait sinon la page au super_admin
      cannot :manage, ActiveAdmin::Page, name: "Mes statistiques d'appel"
      # Ni un autre super admin (ses droits seraient les mêmes, sa vision aussi), ni un compte désactivé
      cannot :impersonate, AdminUser, user_role: 'super_admin'
      cannot :impersonate, AdminUser, is_disabled: true
      cannot :read_sensitive_information, ChildSupport
      cannot :update_sensitive_information, ChildSupport
      cannot :update_ok_for_solicitation, ChildSupport
      can :read_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_ok_for_solicitation, ChildSupport, supporter_id: user.id
    when 'contributor'
      can :manage,
          [Parent, Child, ChildSupport, Workshop, Task, SupportModule, MediaFolder, Medium, Tag, Event, Group, Book, ChildrenSupportModule, Source, RegistrationLimit, ScheduledCall]
      cannot :read_sensitive_information, ChildSupport
      cannot :update_sensitive_information, ChildSupport
      cannot :update_ok_for_solicitation, ChildSupport
      can :read_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_ok_for_solicitation, ChildSupport, supporter_id: user.id
      cannot :assign_supporter, ChildSupport
      can :assign_supporter, ChildSupport if ENV['SUPPORTER_ASSIGNMENT_EMAILS'].to_s.downcase.split.include?(user.email.to_s.downcase)
      can :read, [AdminUser, LogisticExport]
      can :download, LogisticExport
      can :upsert_shipment_date, Book
      can :sav_management, Book
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :manage, ActiveAdmin::Page, name: 'Module'
      can :manage, ActiveAdmin::Page, name: 'Messages'
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Restart Support Form'
      can :manage, ActiveAdmin::Page, name: 'Avoid Disengagement Form'
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      cannot_change_blocked_send_tasks
    when 'reader'
      can :autocomplete, [Group, Tag]
      can :create, Task
      can %i[read update destroy], Task, reporter_id: user.id
      cannot_change_blocked_send_tasks
      can :manage, [Parent, Child, ChildSupport]
      cannot %i[new create destroy discard select_module_for_parent1 select_module_for_parent2 add_child add_parent quit_group create_scheduled_call], [Parent, Child, ChildSupport]
      cannot :read_sensitive_information, ChildSupport
      cannot :update_sensitive_information, ChildSupport
      cannot :update_ok_for_solicitation, ChildSupport
      cannot :assign_supporter, ChildSupport
      cannot :upload_undelivered_books, Parent
      can :read, [Workshop, SupportModule, Group, Book, ChildrenSupportModule, AdminUser, Source, ScheduledCall]
      can :read_content, Book
      can :read, Event, type: 'Events::WorkshopParticipation'
      can %i[create read update], Tag
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :send_message_to_parent1, ChildSupport
      can :send_message_to_parent2, ChildSupport
      cannot :distribute_child_supports_to_callers, Group
    when 'caller'
      can :autocomplete, [Group, Tag] # we use this custom action to search Groups and Tags for users without read permission (ie. in get_recipients)
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :read, AdminUser, id: user.id
      can :create, Task
      can %i[read update destroy], Task, reporter_id: user.id
      cannot_change_blocked_send_tasks
      can :create, Parent
      can %i[read update], Parent, parent1_children: { child_support: { supporter_id: user.id } }
      can %i[read update], Parent, parent2_children: { child_support: { supporter_id: user.id } }
      cannot :upload_undelivered_books, Parent
      # Rattacher un enfant à un parent peut réaffecter la fiche de ce parent au supporter de l'enfant
      # (Child#handle_support_changes) : seulement les parents sans fiche suivie, ou dont les fiches sont les siennes
      can :link_child, Parent do |parent|
        parent.children.kept.joins(:child_support).where('child_supports.supporter_id IS DISTINCT FROM ?', user.id).none?
      end
      can :create, Child
      can %i[read update add_parent add_child], Child, child_support: { supporter_id: user.id }
      can %i[create read update add_parent add_child], ChildSupport, supporter_id: user.id
      can :read_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_ok_for_solicitation, ChildSupport, supporter_id: user.id
      can :create, ChildrenSupportModule
      can %i[read update], ChildrenSupportModule, child: { child_support: { supporter_id: user.id } }
      can :read, SupportModule
      # Pages du livre (couverture + photos intérieures) ouvertes depuis la fiche de suivi, sans accès à la fiche technique.
      can :read_content, Book
      can :read, Event, type: 'Events::TextMessage', related_type: 'Parent', related_id: Parent.joins(parent1_children: :child_support).where(child_supports: { supporter_id: user.id }).pluck(:id)
      can :read, Event, type: 'Events::TextMessage', related_type: 'Parent', related_id: Parent.joins(parent2_children: :child_support).where(child_supports: { supporter_id: user.id }).pluck(:id)
      can :read, Event, type: 'Events::WorkshopParticipation', related_type: 'Parent', related_id: Parent.joins(parent1_children: :child_support).where(child_supports: { supporter_id: user.id }).pluck(:id)
      can :read, Event, type: 'Events::WorkshopParticipation', related_type: 'Parent', related_id: Parent.joins(parent2_children: :child_support).where(child_supports: { supporter_id: user.id }).pluck(:id)
      cannot :read, [Events::OtherEvent, Events::SurveyResponse]
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Restart Support Form'
      can :manage, ActiveAdmin::Page, name: 'Avoid Disengagement Form'
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :manage, ActiveAdmin::Page, name: 'Réglages de RDV'
      can :manage, ActiveAdmin::Page, name: "Mes statistiques d'appel"
      can :manage, CallSessionDateOverride, admin_user_id: user.id
      can :select_module_for_parent1, ChildSupport, supporter_id: user.id
      can :select_module_for_parent2, ChildSupport, supporter_id: user.id
      can :send_message_to_parent1, ChildSupport, supporter_id: user.id
      can :send_message_to_parent2, ChildSupport, supporter_id: user.id
      can :scheduled_call_reminder, ChildSupport, supporter_id: user.id
      can :create_scheduled_call, ChildSupport, supporter_id: user.id
      can :read, ScheduledCall, admin_user_id: user.id
    when 'animator'
      can :read, AdminUser, id: user.id
      can :autocomplete, [Group, Tag]
      can :create, Task
      can %i[read update destroy], Task, reporter_id: user.id
      cannot_change_blocked_send_tasks
      can :manage, [Parent, Child, ChildSupport, ChildrenSupportModule]
      cannot %i[destroy discard], [Parent, Child, ChildSupport, ChildrenSupportModule]
      cannot :read_sensitive_information, ChildSupport
      cannot :update_sensitive_information, ChildSupport
      cannot :update_ok_for_solicitation, ChildSupport
      can :read_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_sensitive_information, ChildSupport, supporter_id: user.id
      can :update_ok_for_solicitation, ChildSupport, supporter_id: user.id
      cannot :assign_supporter, ChildSupport
      cannot :upload_undelivered_books, Parent
      # Rattacher un enfant à un parent peut réaffecter la fiche de ce parent au supporter de l'enfant
      # (Child#handle_support_changes) : seulement les parents sans fiche suivie, ou dont les fiches sont les siennes
      cannot :link_child, Parent
      can :link_child, Parent do |parent|
        parent.children.kept.joins(:child_support).where('child_supports.supporter_id IS DISTINCT FROM ?', user.id).none?
      end
      can :manage, Workshop
      can :manage, Event, type: %w[Events::TextMessage Events::WorkshopParticipation]
      cannot :read, [Events::OtherEvent, Events::SurveyResponse]
      can :read, SupportModule
      can :read_content, Book
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :manage, ActiveAdmin::Page, name: 'Stop Support Form'
      can :manage, ActiveAdmin::Page, name: 'Restart Support Form'
      can :manage, ActiveAdmin::Page, name: 'Avoid Disengagement Form'
      can :manage, ActiveAdmin::Page, name: 'Message'
      can :manage, ActiveAdmin::Page, name: 'Réglages de RDV'
      can :manage, ActiveAdmin::Page, name: "Mes statistiques d'appel"
      can :manage, CallSessionDateOverride, admin_user_id: user.id
      can :select_module_for_parent1, ChildSupport, supporter_id: user.id
      can :select_module_for_parent2, ChildSupport, supporter_id: user.id
      can :send_message_to_parent1, ChildSupport, supporter_id: user.id
      can :send_message_to_parent2, ChildSupport, supporter_id: user.id
      can :scheduled_call_reminder, ChildSupport, supporter_id: user.id
      can :create_scheduled_call, ChildSupport, supporter_id: user.id
      can :read, ScheduledCall, admin_user_id: user.id
    end
  end

  def can?(action, subject, *extra_args)
    while subject.is_a?(Draper::Decorator)
      subject = subject.model
    end
    return false if @read_only && !impersonation_permits?(action, subject)

    super(action, subject, *extra_args)
  end

  private

  # La tâche d'un envoi bloqué ne se clôt que par la relance ou l'archivage de
  # l'envoi (super_admin) : son auteur la lit, sans pouvoir la modifier ni la
  # supprimer. À appeler après les `can` du rôle, pour l'emporter sur eux.
  def cannot_change_blocked_send_tasks
    cannot %i[update destroy discard], Task, related_type: 'BlockedSendAttempt'
  end

  def impersonation_permits?(action, subject)
    subject.is_a?(ActiveAdmin::Page) || action.to_sym.in?(IMPERSONATION_ACTIONS)
  end
end
