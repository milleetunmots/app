class Media::TextMessagesBundleDraft < Medium

  include Media::TextMessagesBundleConcern

  def undraft
    update_attribute :type, 'Media::TextMessagesBundle'
  end

end
