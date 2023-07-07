module Bubble
  class ImportBubbleModuleService

    def initialize
      @uri = URI("#{ENV['BUBBLE_DATA_API_URL']}/module")
    end

    def call
    end
  end
end
