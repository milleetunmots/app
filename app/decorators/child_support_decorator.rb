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
          li child.admin_link
        end
      end
    end
  end

  PROGRESS_COLORS = {
    1 => :red,
    2 => :yellow,
    3 => :green
  }

  def call1_parent_progress_index
    progress model.call1_parent_progress_index
  end

  def call2_program_investment_index
    progress model.call2_program_investment_index
  end

  def call3_program_investment_index
    progress model.call3_program_investment_index
  end

  def parent1
    parent model.parent1
  end

  def parent2
    parent model.parent2
  end

  def important_information
    h.content_tag :div, model.important_information, class: 'free-text'
  end

  def call1_parent_actions
    h.content_tag :div, model.call1_parent_actions, class: 'free-text'
  end

  def call1_language_development
    h.content_tag :div, model.call1_language_development, class: 'free-text'
  end

  def call1_notes
    h.content_tag :div, model.call1_notes, class: 'free-text'
  end

  def call1_parent_progress
    if v = model.call1_parent_progress
      ChildSupport.human_attribute_name("call1_parent_progress.#{v}")
    end
  end

  def call2_technical_information
    h.content_tag :div, model.call2_technical_information, class: 'free-text'
  end

  def call2_content_usage
    h.content_tag :div, model.call2_content_usage, class: 'free-text'
  end

  def call2_program_investment
    if v = model.call2_program_investment
      ChildSupport.human_attribute_name("call2_program_investment.#{v}")
    end
  end

  def call2_language_development
    h.content_tag :div, model.call2_language_development, class: 'free-text'
  end

  def call2_goals
    h.content_tag :div, model.call2_goals, class: 'free-text'
  end

  def call2_notes
    h.content_tag :div, model.call2_notes, class: 'free-text'
  end

  def call3_technical_information
    h.content_tag :div, model.call3_technical_information, class: 'free-text'
  end

  def call3_content_usage
    h.content_tag :div, model.call3_content_usage, class: 'free-text'
  end

  def call3_program_investment
    if v = model.call3_program_investment
      ChildSupport.human_attribute_name("call3_program_investment.#{v}")
    end
  end

  def call3_language_development
    h.content_tag :div, model.call3_language_development, class: 'free-text'
  end

  def call3_goals
    h.content_tag :div, model.call3_goals, class: 'free-text'
  end

  def call3_notes
    h.content_tag :div, model.call3_notes, class: 'free-text'
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
