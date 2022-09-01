class AddTypeformAdditionalInfoToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :help_my_child_to_learn_is_important, :string
    add_column :parents, :would_like_to_do_more, :string
    add_column :parents, :would_receive_advices, :string
  end
end

