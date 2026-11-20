class Media::SyncRcsModelsJob < ApplicationJob

  def perform(text_messages_bundle_id, changed_indexes)
    bundle = Media::TextMessagesBundle.find_by(id: text_messages_bundle_id)
    return unless bundle

    service = Media::SyncRcsModelsService.new(bundle, changed_indexes: changed_indexes).call
    service.errors.each { |message, data| Rollbar.error(message, **data) }
  end
end
