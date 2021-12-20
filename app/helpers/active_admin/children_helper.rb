module ActiveAdmin::ChildrenHelper

  def child_gender_select_collection(with_unknown: false)
    if with_unknown
      [
        [
          Child.human_attribute_name('gender.x'),
          ''
        ]
      ]
    else
      []
    end + Child::GENDERS.map do |v|
      [
        Child.human_attribute_name("gender.#{v}"),
        v
      ]
    end
  end

  def child_group_select_collection
    Group.order(:name).map(&:decorate)
  end

  def child_group_status_select_collection
    Child::GROUP_STATUS.map do |v|
      [
        Child.human_attribute_name("group_status.#{v}"),
        v
      ]
    end
  end

  def child_parent_select_collection
    Parent.order(:first_name, :last_name).map(&:decorate)
  end

  def child_registration_source_select_collection
    Child::REGISTRATION_SOURCES.map do |v|
      [
        Child.human_attribute_name("registration_source.#{v}"),
        v
      ]
    end
  end

  def child_registration_source_select_collection_for_pros
    [
      ['un·e professionnel·le de PMI', :pmi],
      ['un·e orthophoniste', :therapist],
      ['un·e professionnel·le de santé', :pmi],
      ['un·e autre partenaire de 1001mots (centre social, association, crèche...)', :other]
    ]
  end

  def child_registration_pmi_detail_collection
    Child::PMI_LIST.map do |v|
      [Child.human_attribute_name("pmi_detail.#{v}"), v]
    end
  end

  def child_registration_source_details_suggestions
    Child.pluck('DISTINCT ON (LOWER(registration_source_details)) registration_source_details').compact.sort_by(&:downcase)
  end

  def families_count
    Child.families_count
  end

  def fathers_count
    Child.fathers_count
  end

  def children_count
    Child.limit(nil).count
  end

end
