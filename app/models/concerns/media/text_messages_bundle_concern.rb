module Media::TextMessagesBundleConcern
  extend ActiveSupport::Concern

  included do
    # ---------------------------------------------------------------------------
    # relations
    # ---------------------------------------------------------------------------

    belongs_to :image1,
               class_name: 'Media::Image',
               optional: true
    belongs_to :image2,
               class_name: 'Media::Image',
               optional: true
    belongs_to :image3,
               class_name: 'Media::Image',
               optional: true

    belongs_to :link1,
               class_name: :Medium,
               optional: true
    belongs_to :link2,
               class_name: :Medium,
               optional: true
    belongs_to :link3,
               class_name: :Medium,
               optional: true

    # ---------------------------------------------------------------------------
    # validations
    # ---------------------------------------------------------------------------

    validates :body1, presence: true
    validates :body2,
              presence: true,
              if: Proc.new { |o| o.image2 || o.link2 }
    validates :body3,
              presence: true,
              if: Proc.new { |o| o.image3 || o.link3 }
  end
end
