class ArchiveCall4AndCall5Data < ActiveRecord::Migration[7.0]
  def up
    create_table :child_support_call_archives do |t|
      t.references :child_support, null: false, foreign_key: true

      t.text :call4_technical_information
      t.text :call4_parent_actions
      t.text :call4_language_development
      t.text :call4_goals
      t.text :call4_notes
      t.string :call4_status
      t.text :call4_status_details
      t.integer :call4_duration
      t.string :call4_language_awareness
      t.string :call4_parent_progress
      t.string :call4_sendings_benefits
      t.text :call4_sendings_benefits_details
      t.string :call4_reading_frequency
      t.string :call4_tv_frequency
      t.text :call4_goals_tracking
      t.text :call4_goals_sms
      t.string :call4_previous_goals_follow_up
      t.string :call4_attempt
      t.string :call4_review
      t.boolean :call4_talk_needed
      t.text :call4_why_talk_needed

      t.text :call5_technical_information
      t.text :call5_parent_actions
      t.text :call5_language_development
      t.text :call5_goals
      t.text :call5_notes
      t.string :call5_status
      t.text :call5_status_details
      t.integer :call5_duration
      t.string :call5_language_awareness
      t.string :call5_parent_progress
      t.string :call5_sendings_benefits
      t.text :call5_sendings_benefits_details
      t.string :call5_reading_frequency
      t.string :call5_tv_frequency
      t.text :call5_goals_tracking
      t.text :call5_goals_sms
      t.string :call5_attempt
      t.string :call5_review
      t.boolean :call5_talk_needed
      t.text :call5_why_talk_needed

      t.timestamps
    end

    # copy data only for records that have at least one non-null and non-empty call4/call5 field
    call4_columns = %w[
      call4_technical_information call4_parent_actions call4_language_development
      call4_goals call4_notes call4_status call4_status_details call4_duration
      call4_language_awareness call4_parent_progress call4_sendings_benefits
      call4_sendings_benefits_details call4_reading_frequency call4_tv_frequency
      call4_goals_tracking call4_goals_sms call4_previous_goals_follow_up
      call4_attempt call4_review call4_talk_needed call4_why_talk_needed
    ]

    call5_columns = %w[
      call5_technical_information call5_parent_actions call5_language_development
      call5_goals call5_notes call5_status call5_status_details call5_duration
      call5_language_awareness call5_parent_progress call5_sendings_benefits
      call5_sendings_benefits_details call5_reading_frequency call5_tv_frequency
      call5_goals_tracking call5_goals_sms call5_attempt call5_review
      call5_talk_needed call5_why_talk_needed
    ]

    all_columns = call4_columns + call5_columns

    # WHERE clause: at least one field is not null AND not empty
    # For boolean fields, we check if they are true
    # For integer fields (duration), we check if not null
    # For string/text fields, we check if not null and not empty string
    boolean_columns = %w[call4_talk_needed call5_talk_needed]
    integer_columns = %w[call4_duration call5_duration]

    where_conditions = all_columns.map do |col|
      if boolean_columns.include?(col)
        "#{col} = true"
      elsif integer_columns.include?(col)
        "#{col} IS NOT NULL"
      else
        "(#{col} IS NOT NULL AND #{col} <> '')"
      end
    end.join(' OR ')

    execute <<-SQL
      INSERT INTO child_support_call_archives (
        child_support_id,
        #{all_columns.join(', ')},
        created_at,
        updated_at
      )
      SELECT
        id,
        #{all_columns.join(', ')},
        NOW(),
        NOW()
      FROM child_supports
      WHERE #{where_conditions}
    SQL
  end

  def down
    drop_table :child_support_call_archives
  end
end
