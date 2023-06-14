# == Schema Information
#
# Table name: airtables
#
#  id            :bigint           not null, primary key
#  siret_number  :string
#  status        :string
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :bigint
#
# Indexes
#
#  index_airtables_on_admin_user_id  (admin_user_id)
#  index_airtables_on_type           (type)
#

class Airtables::Caller < Airtable

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :siret_number, presence: true
  validtes :status, presence: true

end
