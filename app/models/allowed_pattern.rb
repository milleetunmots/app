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

# Generic allow-list of patterns used to validate external content (URLs and
# phone numbers, other kinds can be added later without a migration).
class AllowedPattern < ApplicationRecord

  KINDS = %w[url phone_number].freeze

  MATCH_TYPES_BY_KIND = {
    'url' => %w[domain exact],
    # Une tranche de numéros est un besoin de blacklist (BlockedPattern), pas de
    # whitelist : on n'autorise que des numéros précis.
    'phone_number' => %w[exact]
  }.freeze

  # Schéma d'une url absolue (cf. canonicalize_url).
  SCHEME_REGEX = %r{\A[a-z][a-z0-9+.-]*://}i

  # Un numéro whitelisté est déjà canonicalisé par normalize_value : il ne reste
  # que des chiffres. Le minimum de 3 écarte les saisies tronquées.
  PHONE_VALUE_REGEX = /\A\d{3,15}\z/

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

    host = extract_host(url)
    host.present? && normalize_host(host) == normalize_host(app_host)
  end

  def self.normalize_host(host)
    host.to_s.downcase.delete_prefix('www.')
  end

  # allowed_numbers : ensemble déjà chargé, pour éviter deux requêtes par numéro
  # quand on en contrôle plusieurs d'affilée (cf.
  # BlockedSendAttempt::PhoneNumberSendGuard).
  def self.phone_allowed?(canonical_number, allowed_numbers: nil)
    return false if canonical_number.blank?

    (allowed_numbers || allowed_phone_numbers).include?(canonical_number)
  end

  # Les numéros Aircall sont nos propres lignes : toujours autorisés, sans qu'un
  # pattern ait à être saisi.
  def self.allowed_phone_numbers
    where(kind: 'phone_number').pluck(:value).to_set.merge(AdminUser.aircall_numbers)
  end

  # Les urls contrôlées viennent de saisies humaines (médiathèque, import
  # Airtable) ou de messages : espaces autour, et très souvent pas de schéma
  # ("form.typeform.com/to/abc"). URI.parse voit alors un chemin et non un host,
  # renvoie nil, et aucun pattern `domain` ne peut matcher : un domaine pourtant
  # autorisé était refusé selon la façon dont l'url était écrite.
  # On canonicalise donc systématiquement avant toute comparaison.
  def self.canonicalize_url(url)
    candidate = url.to_s.strip
    return '' if candidate.empty?

    candidate.match?(SCHEME_REGEX) ? candidate : "https://#{candidate}"
  end

  # URI.parse lève InvalidURIError dès qu'un caractère non ascii ou un espace
  # traîne dans le chemin ou la query ("…/to/abc?prénom=Zoé") : sans le repli sur
  # une url échappée, ces urls étaient elles aussi refusées.
  def self.extract_host(url)
    canonical = canonicalize_url(url)
    URI.parse(canonical).host
  rescue URI::Error
    begin
      URI.parse(URI::DEFAULT_PARSER.escape(canonical)).host
    rescue URI::Error
      nil
    end
  end

  # URI#normalize downcase le schéma et le host (et complète le chemin vide
  # en "/"), sans toucher à la casse du chemin.
  def self.normalize_exact_url(url)
    URI.parse(canonicalize_url(url)).normalize.to_s
  rescue URI::Error
    canonicalize_url(url)
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

    if kind == 'phone_number'
      self.value = PhoneNormalizationConcern.canonical(value)
      return
    end

    self.value = value.downcase if match_type == 'domain'
    # Uniquement si la valeur est déjà une url absolue : canonicaliser une valeur
    # sans schéma lui ajouterait le https:// que value_format_matches_match_type
    # doit justement refuser sur un pattern `exact`.
    self.value = self.class.normalize_exact_url(value) if match_type == 'exact' && absolute_url_value?
  end

  def match_type_allowed_for_kind
    return if kind.blank?

    allowed_match_types = MATCH_TYPES_BY_KIND[kind] || []
    return if allowed_match_types.include?(match_type)

    errors.add(:match_type, "n'est pas valide pour le type #{kind}")
  end

  # Le match_type `exact` existe pour les deux kinds : on discrimine sur le kind
  # avant de contrôler le format attendu.
  def value_format_matches_match_type
    return if value.blank?
    return validate_url_value_format if kind == 'url'

    validate_phone_number_value_format if kind == 'phone_number'
  end

  def validate_url_value_format
    case match_type
    when 'domain'
      errors.add(:value, 'doit être un domaine sans schéma ni chemin (ex: monpartenaire.fr), pas une URL complète') unless domain_value?
    when 'exact'
      errors.add(:value, 'doit être une URL complète avec son schéma (ex: https://exemple.fr/page), pas un simple domaine') unless absolute_url_value?
    end
  end

  def validate_phone_number_value_format
    return if value.match?(PHONE_VALUE_REGEX)

    errors.add(:value, 'doit être un numéro de téléphone (ex: 0810123456, +33810123456)')
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
    host = self.class.extract_host(url)
    return false if host.blank?

    normalized_host = self.class.normalize_host(host)
    normalized_domain = self.class.normalize_host(value)
    normalized_host == normalized_domain || normalized_host.end_with?(".#{normalized_domain}")
  end
end
