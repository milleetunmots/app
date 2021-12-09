class WelcomeFormResponse < ApplicationRecord
  self.primary_key = "response_id"
  validates :form_item, presence: true

end
