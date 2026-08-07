class SeedBuiltinUrlAllowedPatterns < ActiveRecord::Migration[7.0]

  # calendly.com : les rappels de RDV (Aircall::SendCalendlyReminderJob) et les
  # variables {CALLx_CALENDLY_LINK} contiennent des liens Calendly — sans ce
  # pattern, ils seraient bloqués dès l'activation du filtre.
  def up
    execute <<~SQL.squish
      INSERT INTO allowed_patterns (kind, match_type, value, created_at, updated_at)
      VALUES
        ('url', 'domain', 'form.typeform.com', NOW(), NOW()),
        ('url', 'domain', 'videoask.com', NOW(), NOW()),
        ('url', 'domain', 'calendly.com', NOW(), NOW())
      ON CONFLICT (kind, match_type, value) DO NOTHING
    SQL
  end

  def down
    execute <<~SQL.squish
      DELETE FROM allowed_patterns
      WHERE kind = 'url' AND match_type = 'domain' AND value IN ('form.typeform.com', 'videoask.com', 'calendly.com')
    SQL
  end
end
