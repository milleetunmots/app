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
require 'rails_helper'

RSpec.describe BookShipmentDate do
  describe '.cycle_after' do
    it 'adds 45 days and moves to the next monday' do
      # 08/06/2026 est un lundi, +45 jours donne le jeudi 23/07/2026
      expect(described_class.cycle_after(Date.new(2026, 6, 8))).to eq(Date.new(2026, 7, 27))
    end

    it 'keeps the date when +45 days already falls on a monday' do
      # 05/06/2026 est un vendredi, +45 jours donne le lundi 20/07/2026
      expect(described_class.cycle_after(Date.new(2026, 6, 5))).to eq(Date.new(2026, 7, 20))
    end
  end

  describe '.reschedule_following' do
    it 'moves the following date onto the cycle of the given one' do
      first = described_class.create!(date: Date.current + 10.days)
      following = described_class.create!(date: Date.current + 60.days)

      result = described_class.reschedule_following(first)

      expect(result).to eq(following)
      expect(following.reload.date).to eq(described_class.cycle_after(first.date))
    end

    it 'creates the following date when none exists yet' do
      first = described_class.create!(date: Date.current + 10.days)

      expect { described_class.reschedule_following(first) }.to change(described_class, :count).by(1)
      expect(described_class.upcoming.last.date).to eq(described_class.cycle_after(first.date))
    end

    it 'never picks the given date as its own following date' do
      first = described_class.create!(date: Date.current + 10.days)

      result = described_class.reschedule_following(first)

      expect(result).not_to eq(first)
      expect(first.reload.date).to eq(Date.current + 10.days)
    end
  end

  describe 'date validation' do
    it 'accepts a future date' do
      shipment_date = described_class.new(date: Date.current + 10.days)

      expect(shipment_date).to be_valid
    end

    it 'accepts the current date' do
      shipment_date = described_class.new(date: Date.current)

      expect(shipment_date).to be_valid
    end

    it 'rejects a past date' do
      shipment_date = described_class.new(date: Date.current - 1.day)

      expect(shipment_date).not_to be_valid
      expect(shipment_date.errors.full_messages).to include('La date de renvoi ne peut pas être dans le passé.')
    end

    it 'rejects moving an existing date to the past' do
      shipment_date = described_class.create!(date: Date.current + 10.days)

      shipment_date.date = Date.current - 1.day

      expect(shipment_date).not_to be_valid
    end

    it 'still allows saving an existing record whose date has become past' do
      shipment_date = described_class.new(date: Date.current - 10.days)
      shipment_date.save!(validate: false)

      expect(shipment_date.reload.save).to be(true)
    end
  end
end
