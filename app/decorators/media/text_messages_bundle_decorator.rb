class Media::TextMessagesBundleDecorator < MediumDecorator

  (1..3).each do |msg_idx|

    define_method("truncated_body#{msg_idx}") do
      v = model.send("body#{msg_idx}")
      return nil if v.nil?
      v.truncate 160,
                 separator: /\s/,
                 omission: ' (…)'
    end

    define_method("image#{msg_idx}_tag") do |options = {}|
      v = model.send("image#{msg_idx}")
      return nil if v.nil?
      v.decorate.file_tag(options)
    end

    define_method("image#{msg_idx}_admin_link") do |options = {}|
      v = model.send("image#{msg_idx}")
      return nil if v.nil?
      v.decorate.admin_link(options)
    end

    define_method("image#{msg_idx}_admin_link_with_image") do |options = {}|
      v = model.send("image#{msg_idx}")
      return nil if v.nil?

      h.content_tag :div, class: 'autowrap' do
        # (
        #   send("image#{msg_idx}_admin_link")
        # ) + (
        #   h.content_tag(:div, '', class: 'autospace')
        # ) + (
          send(
            "image#{msg_idx}_admin_link",
            label: send("image#{msg_idx}_tag", options)
          )
        # )
      end
    end

    define_method("link#{msg_idx}_admin_link") do
      v = model.send("link#{msg_idx}")
      return nil if v.nil?
      v.decorate.admin_link
    end

  end

  def icon_class
    :comments
  end

  def comments_indicator
    if model.field_comments.any?
      tooltip = model.field_comments.decorate.map do |field_comment|
        "<b>#{field_comment.field}</b> : #{field_comment.content}"
      end.join('<br/>')

      h.content_tag :i,
                    '',
                    class: 'fas fa-comment txt-red',
                    title: tooltip,
                    data: { tooltip: {} }
    end
  end

  def preview
    arbre do
      div class: 'body-image' do
        div class: 'body' do
          model.body1
        end
        div class: 'image' do
          image1_tag
        end
      end
      div class: 'body-image' do
        div class: 'body' do
          model.body2
        end
        div class: 'image' do
          image2_tag
        end
      end
      div class: 'body-image' do
        div class: 'body' do
          model.body3
        end
        div class: 'image' do
          image3_tag
        end
      end
    end
  end

end
