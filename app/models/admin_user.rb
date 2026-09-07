# == Schema Information
#
# Table name: admin_users
#
#  id                          :bigint           not null, primary key
#  aircall_phone_number        :string
#  automatic_sms_activated_at  :datetime
#  calendly_event_type_uris    :jsonb
#  calendly_user_uri           :string
#  can_export_data             :boolean          default(FALSE), not null
#  can_send_automatic_sms      :boolean          default(TRUE), not null
#  can_treat_task              :boolean          default(FALSE), not null
#  current_sign_in_at          :datetime
#  current_sign_in_ip          :inet
#  email                       :string           default(""), not null
#  encrypted_password          :string           default(""), not null
#  group_subscriptions         :jsonb            not null
#  is_disabled                 :boolean          default(FALSE)
#  last_sign_in_at             :datetime
#  last_sign_in_ip             :inet
#  name                        :string
#  otp_attempts                :integer          default(0), not null
#  otp_code_digest             :string
#  otp_sent_at                 :datetime
#  phone_number                :string
#  remember_created_at         :datetime
#  reset_password_sent_at      :datetime
#  reset_password_token        :string
#  sign_in_count               :integer          default(0), not null
#  sms_daily_recipients_limit  :integer          default(200), not null
#  sms_hourly_recipients_limit :integer          default(50), not null
#  two_factor_enabled          :boolean          default(FALSE), not null
#  user_role                   :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  aircall_number_id           :bigint
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class AdminUser < ApplicationRecord

  ROLES = %w[super_admin contributor reader caller animator].freeze
  COMMON_PASSWORDS = %w[1001 mots password azerty 1234 motdepasse qwerty 12345 000 bonjour soleil abc 111].freeze

  OTP_LENGTH = 6
  OTP_VALIDITY = 10.minutes
  OTP_MAX_ATTEMPTS = 5
  OTP_RESEND_DELAY = 60.seconds

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :reported_tasks, class_name: 'Task', foreign_key: 'reporter_id', dependent: :nullify
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id', dependent: :nullify
  has_many :workshops, foreign_key: 'animator_id', dependent: :nullify
  has_many :child_supports, foreign_key: 'supporter_id', inverse_of: :supporter, dependent: :nullify
  has_many :children, through: :child_supports
  has_many :scheduled_calls, dependent: :nullify
  # dependent: :destroy et non :nullify comme ses voisins : admin_user_id
  # est null: false sur sms_send_records.
  has_many :sms_send_records, dependent: :destroy

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :user_role, inclusion: { in: ROLES }
  validates :sms_hourly_recipients_limit, :sms_daily_recipients_limit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :password, format: { with: REGEX_VALID_PASSWORD, message: INVALID_PASSWORD_MESSAGE }, unless: -> { password.blank? }
  validate :common_password
  validates :phone_number,
            phone: {
              types: :mobile,
              countries: :fr,
              message: 'doit être un mobile français valide'
            },
            allow_blank: true
  validates :phone_number, presence: true, if: :two_factor_enabled?

  scope :callers, -> { where(user_role: 'caller') }
  scope :supporters, -> { joins(:child_supports).distinct }
  scope :account_disabled, -> { where(is_disabled: true) }
  scope :account_not_disabled, -> { where(is_disabled: false) }
  scope :beta_test_supporters_who_cannot_send_automatic_sms, -> { supporters.where(email: ENV['BETA_TEST_CALLERS_EMAIL'].to_s.split).where(can_send_automatic_sms: false) }

  before_save :set_automatic_sms_activated_at, if: -> { will_save_change_to_can_send_automatic_sms?(to: true) }
  before_save :format_phone_number, if: -> { will_save_change_to_phone_number? }
  before_save :forget_remembered_sessions, if: -> { will_save_change_to_two_factor_enabled?(to: true) }
  after_create :set_aircall_phone_number
  after_create_commit :export_to_sheet

  def admin?
    user_role == 'super_admin'
  end

  def contributor?
    user_role == 'contributor'
  end

  def reader?
    user_role == 'reader'
  end

  def caller?
    user_role == 'caller'
  end

  def animator?
    user_role == 'animator'
  end

  def caller_or_animator?
    caller? || animator?
  end

  def supporter?
    child_supports.any?
  end

  def active_for_authentication?
    super and !self.is_disabled?
  end

  def inactive_message
    "Ce compte n'est pas activé."
  end

  # Retourne le code en clair : il n'est jamais persisté, seul son hash l'est.
  # Les écritures du cycle de vie du code sautent délibérément validations et
  # callbacks : un compte dont le mot de passe stocké ne satisfait plus la
  # politique actuelle doit quand même pouvoir mener sa connexion 2FA à terme.
  # rubocop:disable Rails/SkipsModelValidations
  def generate_otp!
    code = format("%0#{OTP_LENGTH}d", SecureRandom.random_number(10**OTP_LENGTH))
    update_columns(
      otp_code_digest: BCrypt::Password.create(code),
      otp_sent_at: Time.current,
      otp_attempts: 0,
      updated_at: Time.current
    )
    code
  end

  def verify_otp(code)
    # Le verrou couvre la comparaison ET l'effacement. Sans lui, deux requêtes
    # portant le bon code peuvent toutes les deux comparer le même digest avant
    # que la première ne l'efface, et ouvrir deux sessions avec un OTP supposé
    # à usage unique. with_lock recharge aussi l'état courant depuis la base.
    with_lock do
      if otp_code_digest.blank?
        :no_code
      elsif otp_expired?
        :expired
      elsif BCrypt::Password.new(otp_code_digest) == code.to_s
        clear_otp!
        :ok
      else
        register_failed_otp_attempt!
      end
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  def otp_expired?
    otp_sent_at.blank? || otp_sent_at < OTP_VALIDITY.ago
  end

  def otp_resendable?
    otp_sent_at.blank? || otp_sent_at < OTP_RESEND_DELAY.ago
  end

  # otp_sent_at n'est pas effacé : c'est l'horloge de la limite « un envoi par
  # minute et par compte », indépendante du cycle de vie du code. La remettre à
  # zéro ici rendrait un renvoi immédiatement légal après un blocage pour trop
  # de tentatives. verify_otp court-circuite sur otp_code_digest avant de la lire.
  # rubocop:disable Rails/SkipsModelValidations
  def clear_otp!
    update_columns(otp_code_digest: nil, otp_attempts: 0, updated_at: Time.current)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def masked_phone_number
    return if phone_number.blank?

    "•• •• •• •• #{phone_number.last(2)}"
  end

  # Retourne le service : l'appelant inspecte `#errors` pour savoir si le SMS
  # est parti. `OTP_VALIDITY.inspect` rend « 10 minutes » : le message reste
  # synchronisé avec la constante.
  def send_otp_by_sms
    SpotHit::SendAdminCodeService.new(
      phone_number,
      Time.zone.now.to_i,
      "1001mots : le code de connexion est #{generate_otp!}. Il expire dans #{OTP_VALIDITY.inspect}."
    ).call
  end

  def self.any_caller_or_animator_with_id?(id)
    exists?(id: id, user_role: ['caller', 'animator'])
  end

  def export_to_sheet
    service = AdminUser::ExportToSheetService.new(self).call
    Rollbar.error('AdminUser::ExportToSheetService', errors: service.errors) if service.errors.any?
  end

  def set_aircall_phone_number
    return if aircall_phone_number.present? && aircall_number_id.present?

    aircall_user_service = Aircall::RetrieveUserService.new.call
    if aircall_user_service.errors.any?
      Rollbar.error("Set phone_number error : #{aircall_user_service.errors}")
      return
    end

    aircall_user = aircall_user_service.users.find do |user|
      (I18n.transliterate(user['name'].downcase.squish) == I18n.transliterate(name.downcase.squish)) ||
        (I18n.transliterate(user['email'].downcase.squish) == I18n.transliterate(email.downcase.squish))
    end
    return unless aircall_user

    aircall_user_service = Aircall::RetrieveUserService.new(user_id: aircall_user['id']).call
    if aircall_user_service.errors.any?
      Rollbar.error("Set phone_number error for #{id} : #{aircall_user_service.errors}")
      return
    end

    aircall_user = aircall_user_service.users.first
    phone_number = aircall_user.try(:[], 'numbers')&.first.try(:[], 'digits')
    number_id = aircall_user.try(:[], 'numbers')&.first.try(:[], 'id')
    unless phone_number && number_id
      Rollbar.error("Set phone number error for #{id} : No digits")
      return
    end

    self.update(aircall_phone_number: Phonelib.parse(phone_number).e164, aircall_number_id: number_id)
  end

  def self.aircall_numbers
    where.not(aircall_phone_number: [nil, ''])
         .pluck(:aircall_phone_number)
         .map { |number| PhoneNormalizationConcern.canonical(number) }
  end

  # Les deux numéros d'un membre de l'équipe peuvent être insérés dans un
  # message sortant : la ligne Aircall pour être rappelé et le mobile personnel
  # utilisé notamment pour la double authentification.
  def self.message_filter_allowed_phone_numbers
    pluck(:aircall_phone_number, :phone_number)
      .flatten
      .compact_blank
      .to_set { |number| PhoneNormalizationConcern.canonical(number) }
  end

  private

  def set_automatic_sms_activated_at
    self.automatic_sms_activated_at = Time.zone.now
  end

  def common_password
    return unless password

    found_common_password = COMMON_PASSWORDS.find { |common_password| password.downcase.include?(common_password) }
    return unless found_common_password

    errors.add(:password, "ne doit pas contenir ce mot trop commun : '#{found_common_password}'")
  end

  def format_phone_number
    self.phone_number = Phonelib.parse(phone_number).e164 if phone_number.present?
  end

  def register_failed_otp_attempt!
    attempts = otp_attempts + 1
    if attempts >= OTP_MAX_ATTEMPTS
      clear_otp!
      :too_many_attempts
    else
      update_columns(otp_attempts: attempts, updated_at: Time.current)
      :invalid
    end
  end

  # Devise valide les cookies « se souvenir de moi » contre remember_created_at :
  # l'annuler révoque tous les cookies en cours du compte. Sans cela, un cookie
  # posé avant l'activation du second facteur ouvrirait des sessions sans code
  # pendant encore deux semaines, Warden n'appelant jamais notre controller.
  def forget_remembered_sessions
    self.remember_created_at = nil
  end
end
