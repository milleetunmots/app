class ChildSupportDecorator < BaseDecorator

  def admin_link
    h.auto_link model
  end

  def display_name
    first_child&.decorate&.name
  end

  def children
    arbre do
      ul do
        model.children.decorate.each do |child|
          li do
            child.admin_link + ' (' + child.age + ')'
          end
        end
      end
    end
  end

  def children_first_names(glue = "\n")
    children_attribute(:first_name, glue)
  end

  def children_last_names(glue = "\n")
    children_attribute(:last_name, glue)
  end

  def children_birthdates(glue = "\n")
    children_attribute(:birthdate, glue)
  end

  def children_ages(glue = "\n")
    children_attribute(:age, glue)
  end

  def children_genders(glue = "\n")
    children_attribute(:gender, glue)
  end

  PROGRESS_COLORS = {
    1 => :red,
    2 => :yellow,
    3 => :green,
    4 => :blue
  }

  def call1_parent_progress_index
    progress model.call1_parent_progress_index
  end

  def call2_parent_progress_index
    progress model.call2_parent_progress_index
  end

  def call3_parent_progress_index
    progress model.call3_parent_progress_index
  end

  def parent1
    parent model.parent1
  end

  def parent2
    parent model.parent2
  end

  def important_information_text
    model.important_information
  end

  def important_information
    h.content_tag :div, important_information_text, class: 'free-text'
  end

  def call1_parent_actions_text
    model.call1_parent_actions
  end

  def call1_parent_actions
    h.content_tag :div, call1_parent_actions_text, class: 'free-text'
  end

  def call1_language_development_text
    model.call1_language_development
  end

  def call1_language_development
    h.content_tag :div, call1_language_development_text, class: 'free-text'
  end

  def call1_notes_text
    model.call1_notes
  end

  def call1_notes
    h.content_tag :div, call1_notes_text, class: 'free-text'
  end

  def call1_parent_progress
    if v = model.call1_parent_progress
      ChildSupport.human_attribute_name("call1_parent_progress.#{v}")
    end
  end

  def call1_reading_frequency
    if v = model.call1_reading_frequency
      ChildSupport.human_attribute_name("call1_reading_frequency.#{v}")
    end
  end

  def call2_technical_information_text
    model.call2_technical_information
  end

  def call2_technical_information
    h.content_tag :div, call2_technical_information_text, class: 'free-text'
  end

  def call2_content_usage_text
    model.call2_content_usage
  end

  def call2_content_usage
    h.content_tag :div, call2_content_usage_text, class: 'free-text'
  end

  def call2_language_awareness
    if v = model.call2_language_awareness
      ChildSupport.human_attribute_name("call2_language_awareness.#{v}")
    end
  end

  def call2_parent_progress
    if v = model.call2_parent_progress
      ChildSupport.human_attribute_name("call2_parent_progress.#{v}")
    end
  end

  def call2_program_investment
    if v = model.call2_program_investment
      ChildSupport.human_attribute_name("call2_program_investment.#{v}")
    end
  end

  def call2_language_development_text
    model.call2_language_development
  end

  def call2_language_development
    h.content_tag :div, call2_language_development_text, class: 'free-text'
  end

  def call2_goals_text
    model.call2_goals
  end

  def call2_goals
    h.content_tag :div, call2_goals_text, class: 'free-text'
  end

  def call2_notes_text
    model.call2_notes
  end

  def call2_notes
    h.content_tag :div, call2_notes_text, class: 'free-text'
  end

  def call3_technical_information_text
    model.call3_technical_information
  end

  def call3_technical_information
    h.content_tag :div, call3_technical_information_text, class: 'free-text'
  end

  def call3_content_usage_text
    model.call3_content_usage
  end

  def call3_content_usage
    h.content_tag :div, call3_content_usage_text, class: 'free-text'
  end

  def call3_language_awareness
    if v = model.call3_language_awareness
      ChildSupport.human_attribute_name("call3_language_awareness.#{v}")
    end
  end

  def call3_parent_progress
    if v = model.call3_parent_progress
      ChildSupport.human_attribute_name("call3_parent_progress.#{v}")
    end
  end

  def call3_sendings_benefits
    if v = model.call3_sendings_benefits
      ChildSupport.human_attribute_name("call3_sendings_benefits.#{v}")
    end
  end

  def call3_language_development_text
    model.call3_language_development
  end

  def call3_language_development
    h.content_tag :div, call3_language_development_text, class: 'free-text'
  end

  def call3_goals_text
    model.call3_goals
  end

  def call3_goals
    h.content_tag :div, call3_goals_text, class: 'free-text'
  end

  def call3_notes_text
    model.call3_notes
  end

  def call3_notes
    h.content_tag :div, call3_notes_text, class: 'free-text'
  end

  def groups
    arbre do
      ul do
        model.children.decorate.each do |child|
          li do
            child.group
          end
        end
      end
    end
  end

  def registration_sources
    arbre do
      ul do
        model.children.decorate.each do |child|
          li do
            child.registration_source
          end
        end
      end
    end
  end

  # def parent1_card
  #   parent_card model.parent1, model.should_contact_parent1
  # end

  # def parent2_card
  #   parent_card model.parent2, model.should_contact_parent2
  # end

  # def children_cards
  #   model.children.each do |child|
  #     h.render 'child', child: child.decorate
  #   end
  # end

  private

  def children_attribute(key, glue)
    result = model.children.decorate.map(&key)
    glue ? result.join(glue) : result
  end

  def progress(index)
    if index
      arbre do
        status_tag index, class: PROGRESS_COLORS[index]
      end
    end
  end

  def parent(parent)
    return nil unless parent
    parent.decorate.admin_link
  end

  # def parent_card(parent, should_contact_parent)
  #  if parent
  #     h.render 'parent', parent: parent.decorate, should_contact_parent: should_contact_parent
  #   end
  # end

end
