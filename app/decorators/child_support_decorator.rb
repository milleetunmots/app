class ChildSupportDecorator < BaseDecorator

  PROGRESS_COLORS = {
    1 => :red,
    2 => :yellow,
    3 => :green,
    4 => :blue
  }

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

  def children_registration_sources(glue = "\n")
    children_attribute(:registration_source, glue)
  end

  def children_present_on
    model.decorate.present_on&.join(", ")
  end

  def children_follow_us_on
    model.decorate.follow_us_on&.join(", ")
  end

  def children_land(glue = "\n")
    children_attribute(:land, glue)
  end

  def children_book_not_received
    model.decorate.book_not_received&.join(", ")
  end

  def children_registration_months_range(glue = "\n")
    children_attribute(:registration_months_range, glue)
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

  def books_quantity
    if model.books_quantity
      ChildSupport.human_attribute_name("books_quantity.#{model.books_quantity}")
    end
  end

  def registration_months_range
    arbre do
      ul do
        model.children.decorate.each do |child|
          li do
            child.registration_months_range
          end
        end
      end
    end
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

  def child_support_groups(glue = "\n")
    children_attribute(:group_name, glue)
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

  (1..5).each do |call_idx|

    define_method("call#{call_idx}_parent_progress_index") do
      progress model.send("call#{call_idx}_parent_progress_index")
    end

    define_method("call#{call_idx}_parent_actions_text") do
      model.send("call#{call_idx}_parent_actions")
    end

    define_method("call#{call_idx}_parent_actions") do
      h.content_tag :div, send("call#{call_idx}_parent_actions_text"), class: 'free-text'
    end

    define_method("call#{call_idx}_language_awareness") do
      if v = model.send("call#{call_idx}_language_awareness")
        ChildSupport.human_attribute_name("call_language_awareness.#{v}")
      end
    end

    define_method("call#{call_idx}_parent_progress") do
      if v = model.send("call#{call_idx}_parent_progress")
        ChildSupport.human_attribute_name("call_parent_progress.#{v}")
      end
    end

    define_method("call#{call_idx}_language_development_text") do
      model.send("call#{call_idx}_language_development")
    end

    define_method("call#{call_idx}_language_development") do
      h.content_tag :div, send("call#{call_idx}_language_development_text"), class: 'free-text'
    end

    define_method("call#{call_idx}_reading_frequency") do
      if v = model.send("call#{call_idx}_reading_frequency")
        ChildSupport.human_attribute_name("call_reading_frequency.#{v}")
      end
    end

    define_method("call#{call_idx}_goals_text") do
      model.send("call#{call_idx}_goals")
    end

    define_method("call#{call_idx}_goals") do
      h.content_tag :div, send("call#{call_idx}_goals_text"), class: 'free-text'
    end

    define_method("call#{call_idx}_notes_text") do
      model.send("call#{call_idx}_notes")
    end

    define_method("call#{call_idx}_notes") do
      h.content_tag :div, send("call#{call_idx}_notes_text"), class: 'free-text'
    end

    define_method("call#{call_idx}_sendings_benefits") do
      if v = model.send("call#{call_idx}_sendings_benefits")
        ChildSupport.human_attribute_name("call_sendings_benefits.#{v}")
      end
    end

    define_method("call#{call_idx}_technical_information_text") do
      model.send("call#{call_idx}_technical_information")
    end

    define_method("call#{call_idx}_technical_information") do
      h.content_tag :div, send("call#{call_idx}_technical_information_text"), class: 'free-text'
    end

  end

  def dropdown_menu_item
    (
      [
        "<b>Suivi ##{model.id}</b>"
      ] +
        model.children.decorate.map do |child|
          child.gendered_name_with_age(with_icon: true)
        end
    ).join('<br/>-&nbsp;').html_safe
  end


  ###

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
