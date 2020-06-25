class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  def self.tagged_with_all(*v)
    tagged_with(v)
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i(tagged_with_all)
  end

  def self.ransackable_scopes_skip_sanitize_args
    ransackable_scopes
  end
end
