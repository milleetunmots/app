module Bubble
  class ImportBubbleModuleService < BubbleService

    def initialize
      super('module')
    end

    def call
      all_modules.each do |item|
        new_module = fill_data(Bubbles::BubbleModule, item, %w[description niveau theme titre age])
        new_module.module_precedent = Bubbles::BubbleModule.find_by(bubble_id: item['module_precedent'])
        new_module.module_suivant = Bubbles::BubbleModule.find_by(bubble_id: item['module_suivant'])
        new_module.video_princ = Bubbles::BubbleVideo.find_by(bubble_id: item['video_princ'])
        new_module.video_tem = Bubbles::BubbleVideo.find_by(bubble_id: item['video_tem'])
        new_module.save
      end
    end

    private

    def all_modules
      all_datas
    end
  end
end
