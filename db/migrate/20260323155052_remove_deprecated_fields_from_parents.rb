class RemoveDeprecatedFieldsFromParents < ActiveRecord::Migration[7.0]
  def change
    remove_column :parents, :help_my_child_to_learn_is_important, :string
    remove_column :parents, :would_like_to_do_more, :string
    remove_column :parents, :would_receive_advices, :string
  end
end
