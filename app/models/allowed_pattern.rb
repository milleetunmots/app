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

  # L'index unique (kind, match_type, value) est case-sensitive : sans
  # normalisation, "Partenaire.FR" et "partenaire.fr" coexisteraient en base.
  before_validation :normalize_value

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

  # patterns : collection déjà chargée, pour éviter une requête par URL quand on
  # en contrôle plusieurs d'affilée (cf. BlockedSendAttempt::UrlSendGuard).
  def self.url_allowed?(url, patterns: nil)
    return false if url.blank?
    return true if app_host?(url)

    (patterns || where(kind: 'url')).any? { |pattern| pattern.url_matches?(url) }
  end

  # Le domaine de l'app est toujours autorisé sans pattern en base : les liens de
  # redirection (/r/:id/:code) sont substitués dans le message avant le guard côté
  # Aircall, et DEFAULT_HOSTNAME varie selon l'environnement.
  def self.app_host?(url)
    app_host = ENV.fetch('DEFAULT_HOSTNAME', nil)
    return false if app_host.blank?

    host =
      begin
        URI.parse(url).host
      rescue URI::InvalidURIError
        nil
      end
    host.present? && normalize_host(host) == normalize_host(app_host)
  end

  def self.normalize_host(host)
    host.to_s.downcase.delete_prefix('www.')
  end

  # URI#normalize downcase le schéma et le host (et complète le chemin vide
  # en "/"), sans toucher à la casse du chemin.
  def self.normalize_exact_url(url)
    URI.parse(url).normalize.to_s
  rescue URI::Error
    url
  end

  def in_use?
    return false unless kind == 'url'

    Medium.for_redirections.any? { |medium| url_matches?(medium.url) }
  end

  def url_matches?(url)
    return false if url.blank?

    case match_type
    when 'exact'
      # Schéma et host sont insensibles à la casse, le chemin reste sensible.
      self.class.normalize_exact_url(url) == self.class.normalize_exact_url(value)
    when 'domain'
      host_matches_domain?(url)
    else
      false
    end
  end

  private

  def normalize_value
    return if value.blank?

    self.value = value.strip
    self.value = value.downcase if match_type == 'domain'
    self.value = self.class.normalize_exact_url(value) if match_type == 'exact'
  end

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

    normalized_host = self.class.normalize_host(host)
    normalized_domain = self.class.normalize_host(value)
    normalized_host == normalized_domain || normalized_host.end_with?(".#{normalized_domain}")
  end
end
