module ActiveAdmin::DiscardHelper

  def link_to_discard(model, options = {})
    classes = [
      options[:class],
      :red
    ].compact.join(' ')

    link_to 'Supprimer',
            [:discard, :admin, model],
            method: :put,
            class: classes
  end

  def link_to_discard_resource(options = {})
    link_to_discard resource, options
  end

  def link_to_undiscard(model, options = {})
    classes = [
      options[:class],
      :green
    ].compact.join(' ')

    link_to 'Restaurer',
            [:undiscard, :admin, model],
            method: :put,
            class: classes
  end

  def link_to_undiscard_resource(options = {})
    link_to_undiscard resource, options
  end

  def link_to_really_destroy(model, options = {})
    classes = [
      options[:class],
      :red
    ].compact.join(' ')

    link_to 'Supprimer définitivement',
            [:really_destroy, :admin, model],
            method: :delete,
            class: classes,
            data: {
              confirm: 'Êtes-vous certain de vouloir supprimer ceci ?'
            }
  end

  def link_to_really_destroy_resource(options = {})
    link_to_really_destroy resource, options
  end

  def discard_links(model, options = {})
    if model.discarded?
      [
        link_to_undiscard(model, options),
        link_to_really_destroy(model, options)
      ].join.html_safe
    else
      link_to_discard(model, options)
    end
  end

  def resource_discard_links(options = {})
    discard_links resource, options
  end

end
