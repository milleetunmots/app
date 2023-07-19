module Bubble
  class ImportBubbleModelsService

    def self.call
      Bubble::ImportBubbleVideoService.new.call
      Bubble::ImportBubbleModuleService.new.call
      Bubble::ImportBubbleContentService.new.call
      Bubble::ImportBubbleSessionService.new.call
    end
  end
end
