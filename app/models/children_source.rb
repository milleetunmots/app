# == Schema Information
#
# Table name: children_sources
#
#  id                      :bigint           not null, primary key
#  details                 :string
#  professional_email      :string
#  re_enrollment           :boolean          default(FALSE)
#  registration_department :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  child_id                :bigint
#  source_id               :bigint
#
# Indexes
#
#  index_children_sources_on_child_id   (child_id)
#  index_children_sources_on_source_id  (source_id)
#
class ChildrenSource < ApplicationRecord
  # Détail posé sur les enfants créés depuis l'admin. Comparé tel quel par le filtre
  # source_details_matches_any (sensible à la casse) : ne pas le dupliquer en dur.
  ADMIN_CREATION_DETAILS = 'Ajouté par 1001mots'.freeze

  belongs_to :source
  belongs_to :child

  delegate :name, to: :source, prefix: false, allow_nil: true

  validates :professional_email,
            format: { with: REGEX_VALID_EMAIL, allow_blank: true, message: "doit être au format adresse email (xxxx@xx.com)." }

end
