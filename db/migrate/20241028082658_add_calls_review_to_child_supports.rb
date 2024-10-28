class AddCallsReviewToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call0_review, :string
    add_column :child_supports, :call1_review, :string
    add_column :child_supports, :call2_review, :string
    add_column :child_supports, :call3_review, :string
  end
end
