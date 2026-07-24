# == Schema Information
#
# Table name: allowed_patterns
#
#  id         :bigint           not null, primary key
#  kind       :string           not null
#  match_type :string           not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_allowed_patterns_on_kind_and_match_type_and_value  (kind,match_type,value) UNIQUE
#

# Generic allow-list of patterns used to validate external content (URLs today,
# other kinds like keyword/phone_number can be added later without a migration).
class AllowedPattern < ApplicationRecord

  KINDS = %w[url].freeze

  MATCH_TYPES_BY_KIND = {
    'url' => %w[domain exact]
  }.freeze

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :match_type, presence: true
  validates :value, presence: true
  validates :value, uniqueness: { scope: %i[kind match_type] }
  validate :match_type_allowed_for_kind
  validate :value_format_matches_match_type

  before_destroy :ensure_not_in_use

  # ---------------------------------------------------------------------------
  # usage
  # ---------------------------------------------------------------------------

  def self.url_allowed?(url)
    return false if url.blank?

    where(kind: 'url').any? { |pattern| pattern.url_matches?(url) }
  end

  def in_use?
    return false unless kind == 'url'

    Medium.for_redirections.any? { |medium| url_matches?(medium.url) }
  end

  def url_matches?(url)
    return false if url.blank?

    case match_type
    when 'exact'
      url == value
    when 'domain'
      host_matches_domain?(url)
    else
      false
    end
  end

  private

  def match_type_allowed_for_kind
    return if kind.blank?

    allowed_match_types = MATCH_TYPES_BY_KIND[kind] || []
    return if allowed_match_types.include?(match_type)

    errors.add(:match_type, "n'est pas valide pour le type #{kind}")
  end

  def value_format_matches_match_type
    return if kind != 'url' || value.blank?

    case match_type
    when 'domain'
      errors.add(:value, 'doit être un domaine sans schéma ni chemin (ex: monpartenaire.fr), pas une URL complète') unless domain_value?
    when 'exact'
      errors.add(:value, 'doit être une URL complète avec son schéma (ex: https://exemple.fr/page), pas un simple domaine') unless absolute_url_value?
    end
  end

  def domain_value?
    value.match?(/\A[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+\z/i)
  end

  def absolute_url_value?
    uri = begin
      URI.parse(value)
    rescue URI::InvalidURIError
      nil
    end
    uri.is_a?(URI::HTTP) && uri.host.present?
  end

  def ensure_not_in_use
    return unless in_use?

    label = match_type == 'domain' ? 'domaine' : 'url'
    errors.add(:base, "Un ou plusieurs médias utilisent encore ce #{label} (#{value}), la suppression est impossible.")
    throw :abort
  end

  def host_matches_domain?(url)
    host =
      begin
        URI.parse(url).host
      rescue URI::InvalidURIError
        nil
      end
    return false if host.blank?

    normalized_host = normalize_host(host)
    normalized_domain = normalize_host(value)
    normalized_host == normalized_domain || normalized_host.end_with?(".#{normalized_domain}")
  end

  def normalize_host(host)
    host.to_s.downcase.delete_prefix('www.')
  end
end
