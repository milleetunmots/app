class TaskDecorator < BaseDecorator

  def title_with_done_icon
    (
      (
        if model.status == 'done'
          h.content_tag :i, '', class: 'fas fa-check-circle txt-green'
        elsif model.status == 'in_progress'
          h.content_tag :i, '', class: 'fas fa-sync-alt txt-yellow'
        else
          h.content_tag :i, '', class: 'fas fa-clock txt-grey'
        end
      ) + ' ' + model.title
    ).html_safe
  end

  def due_date
    if model.due_date
      l model.due_date, format: :default
    end
  end

  def related
    if model.related
      h.auto_link model.related.decorate
    end
  end

  def icon_class
    'clipboard-list'
  end

  def as_autocomplete_result
    h.content_tag :div, class: 'task' do
      (
        h.content_tag :div, class: :title do
          title
        end
      ) + (
        h.content_tag :div, class: :related do
          h.auto_link related
        end
      )
    end
  end

  def display_description
    model.description&.html_safe
  end

end
