module :NameFormatConcern
  extend ActiveSupport::Concern

  def self.format_first_name(first_name)
    first_name.strip.downcase.gsub(/\p{L}+/, &:capitalize)
  end

  def self.format_last_name(last_name)
    last_name.strip.upcase
  end

  included do
    before_validation :format_names

    private

    def format_names
      self.first_name = NameFormatConcern.format_first_name(first_name) if first_name.present?
      self.last_name = NameFormatConcern.format_last_name(last_name) if last_name.present?
    end
  end
end
