module ActiveAdmin::ChildSupportsHelper

  def child_support_supporter_select_collection
    AdminUser.order(:name).map(&:decorate)
  end

  ### shared

  def child_support_call_language_awareness_select_collection
    ChildSupport::LANGUAGE_AWARENESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_language_awareness.#{v}"),
        v
      ]
    end
  end

  def child_support_call_parent_progress_select_collection
    ChildSupport::PARENT_PROGRESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_parent_progress.#{v}"),
        v
      ]
    end
  end

  def child_support_call_review_select_collection
    ChildSupport::CALL_REVIEW_OPTIONS.map do |v|
      [
        ChildSupport.human_attribute_name("call_review.#{v}"),
        v
      ]
    end
  end

  def child_support_call_reading_frequency_select_collection
    ChildSupport::READING_FREQUENCY.reverse.map do |v|
      [
        ChildSupport.human_attribute_name("call_reading_frequency.#{v}"),
        v
      ]
    end
  end

  def child_support_call_tv_frequency_select_collection
    ChildSupport::TV_FREQUENCY.reverse.map do |v|
      [
        ChildSupport.human_attribute_name("call_tv_frequency.#{v}"),
        v
      ]
    end
  end

  def child_support_call_sendings_benefits_select_collection
    ChildSupport::SENDINGS_BENEFITS.map do |v|
      [
        ChildSupport.human_attribute_name("call_sendings_benefits.#{v}"),
        v
      ]
    end
  end

  def child_support_call_family_progress_select_collection
    ChildSupport::FAMILY_PROGRESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_family_progress.#{v}"),
        v
      ]
    end
  end

  def child_support_call_previous_goals_follow_up_select_collection
    ChildSupport::GOALS_FOLLOW_UP.map do |v|
      [
        ChildSupport.human_attribute_name("call_previous_goals_follow_up.#{v}"),
        v
      ]
    end
  end

  def child_support_books_quantity
    ChildSupport::BOOKS_QUANTITY.map do |v|
      [
        ChildSupport.human_attribute_name("books_quantity.#{v}"),
        v
      ]
    end
  end

  def social_network_collection
    ChildSupport::SOCIAL_NETWORK.map { |v| ChildSupport.human_attribute_name("social_network.#{v}") }
  end

  def our_social_network_collection
    ChildSupport::OUR_SOCIAL_NETWORK.map { |v| ChildSupport.human_attribute_name("our_social_network.#{v}") }
  end

  def book_not_received_collection
    ChildSupport::BOOK_NOT_RECEIVED.map { |v| ChildSupport.human_attribute_name("book_not_received.#{v}") }
  end

  def call_status_collection
    ChildSupport::CALL_STATUS.map { |v| ChildSupport.human_attribute_name("call_status.#{v}") }
  end

  def is_bilingual_collection
    ChildSupport::IS_BILINGUAL_OPTIONS.map do |v|
      [
        ChildSupport.human_attribute_name("is_bilingual.#{v}"),
        v
      ]
    end
  end

  def call_statuses_with_nil
    ChildSupport::CALL_STATUS.map do |v|
      [
        ChildSupport.human_attribute_name("call_status.#{v}"),
        ChildSupport.human_attribute_name("call_status.#{v}")
      ]
    end.push(['Non renseigné', 'nil'])
  end

  def child_support_task_titles_with_assignees
    coordinator = AdminUser.find_by(email: ENV['COORDINATOR_EMAIL'])
    operation_project_manager = AdminUser.find_by(email: ENV['OPERATION_PROJECT_MANAGER_EMAIL'])
    return nil if coordinator.nil? || operation_project_manager.nil?

    {
      'Désactiver l’accompagnement d’un des jumeaux, pour qu’il n’y ait plus qu’un seul livre envoyé.' => operation_project_manager.id,
      'Supprimer un doublon pour un même enfant accompagné' => operation_project_manager.id,
      'Réunir une fratrie séparée dans deux cohortes différentes afin qu’elle soit regroupée dans la même cohorte' => operation_project_manager.id,
      'Réactiver les SMS pour un parent ayant envoyé “STOP” par erreur' => operation_project_manager.id,
      'Regrouper une fratrie sur la même fiche de suivi' => operation_project_manager.id,
      'Arrêter l’accompagnement d’un enfant de plus de 3 ans (fratrie et hors fratrie)' => operation_project_manager.id,
      'Ajouter un.e frère / sœur à une fiche de suivi si l’accompagnement de l’aîné.e est déjà terminé' => operation_project_manager.id,
      'Nettoyer une fiche de suivi et archiver le suivi dans la partie “Notes”' => operation_project_manager.id,
      'Rédiger une autre tâche qui n’est pas dans le menu déroulant (après avoir vérifié la FAQ :) !)' => operation_project_manager.id,
      'Je ne sais pas si cela nécessite une tâche' => operation_project_manager.id,
      'Arrêter l’accompagnement d’une famille non consentante' => coordinator.id,
      'Arrêter l’accompagnement d’une famille problématique' => coordinator.id,
      'Arrêter l’accompagnement d’une famille non-francophone' => coordinator.id
    }
  end

  def child_support_task_titles
    return [] if child_support_task_titles_with_assignees.nil?

    child_support_task_titles_with_assignees.keys
  end
end
