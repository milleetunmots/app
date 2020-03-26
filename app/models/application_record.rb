class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.ransackable_scopes_skip_sanitize_args
    ransackable_scopes
  end
end
