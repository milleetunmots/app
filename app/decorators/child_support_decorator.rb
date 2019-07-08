class ChildSupportDecorator < BaseDecorator

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

  private

  def progress(index)
    if index
      arbre do
        status_tag index, class: PROGRESS_COLORS[index]
      end
    end
  end

end
