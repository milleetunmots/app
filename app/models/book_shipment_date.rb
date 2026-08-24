# == Schema Information
#
# Table name: book_shipment_dates
#
#  id         :bigint           not null, primary key
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_book_shipment_dates_on_date  (date) UNIQUE
#
class BookShipmentDate < ApplicationRecord

  CYCLE_DAYS = 45

  validates :date, presence: true, uniqueness: true
  validate :date_cannot_be_in_the_past, if: :date_changed?

  scope :upcoming, -> { where(date: Date.current..).order(:date) }
  scope :past, -> { where(date: ...Date.current).order(:date) }

  # Date du cycle suivant : +45 jours, recalé sur le lundi suivant.
  def self.cycle_after(date)
    base = date + CYCLE_DAYS.days
    base.monday? ? base : base.next_occurring(:monday)
  end

  def self.next_suggested_date
    cycle_after(order(:date).last&.date || Date.current)
  end

  # Recale la date de renvoi suivante sur le cycle de la date passée en
  # argument, en la créant si elle n'existe pas encore. Renvoie
  # l'enregistrement, porteur de ses erreurs s'il n'a pas pu être sauvegardé.
  def self.reschedule_following(shipment_date)
    following = upcoming.where.not(id: shipment_date.id).first || new
    following.date = cycle_after(shipment_date.date)
    following.save
    following
  end

  private

  # Uniquement quand la date est modifiée : les dates déjà enregistrées
  # deviennent passées avec le temps et doivent rester enregistrables.
  def date_cannot_be_in_the_past
    return if date.blank?

    errors.add(:base, :invalid, message: 'La date de renvoi ne peut pas être dans le passé.') if date < Date.current
  end
end
