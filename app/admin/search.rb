ActiveAdmin.register_page "Search" do
  menu false

  controller do
    def index
      term = params[:term]

      # filter Parent & Child results to match caller permissions
      authorized_parent_ids = if current_admin_user.caller?
                                Parent.joins("LEFT JOIN children ON children.parent1_id = parents.id OR children.parent2_id = parents.id")
                                      .joins("INNER JOIN child_supports ON children.child_support_id = child_supports.id")
                                      .where(child_supports: { supporter_id: current_admin_user.id })
                                      .distinct
                                      .select(:id)
                              else
                                Parent.select(:id)
                              end

      authorized_child_ids = if current_admin_user.caller?
                               Child.joins(:child_support)
                                    .where(child_support: { supporter_id: current_admin_user.id })
                                    .select(:id)
                             else
                               Child.select(:id)
                             end

      results = PgSearch.multisearch(term)
                        .where(
                          '(searchable_type = ? AND searchable_id IN (?)) OR ' \
                          '(searchable_type = ? AND searchable_id IN (?))',
                          'Parent', authorized_parent_ids,
                          'Child', authorized_child_ids
                        )

      render json: {
        results: results.map do |document|
          model = document.searchable.decorate
          {
            id: document.id,
            type: document.searchable_type,
            icon: model.icon_class,
            url: url_for([:admin, model.model]),
            html: model.as_autocomplete_result
          }
        end
      }
    end
  end

end
