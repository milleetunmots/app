class BaseDecorator < Draper::Decorator

  delegate_all
  include Rails.application.routes.url_helpers

  attr_accessor :current_admin_user

  def initialize(object, user = nil)
    super(object)
    @current_admin_user = user
  end

  def arbre(&block)
    Arbre::Context.new({}, self, &block).to_s
  end

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    options[:class] = [
      options[:class],
      model.respond_to?(:discarded?) && (model.discarded? ? 'discarded' : 'kept')
    ].compact.join(' ')
    h.link_to txt, [:admin, model], options
  end

  def tags(options = {})
    return unless options[:context]

    config = h.active_admin_resource_for(model.class)
    return unless config

    arbre do
      model.send(options[:context]).each do |tag|
        next if current_admin_user.try(:user_role).eql?('caller') && tag.is_visible_by_callers.eql?(false)

        a tag.name,
          href: config.route_collection_path(nil, q: {tagged_with_all: [tag.name]}),
          class: 'tag_display',
          style: "background-color: #{tag.color || '#CACACA'}"
        text_node "&nbsp;".html_safe
      end
    end
  end

  def territory
    return unless postal_code

    return "Loiret" if [49800, 77460, 77570].include? postal_code.to_i

    case postal_code.to_i / 1000
    when 45 then "Loiret"
    when 78 then "Yvelines"
    when 93 then "Seine-Saint-Denis"
    when 75 then "Paris"
    when 57 then "Moselle"
    else
      nil
    end
  end

  def land
    return unless postal_code

    return 'Paris 18 eme' if Parent::PARIS_18_EME_POSTAL_CODE.include? postal_code

    return 'Paris 20 eme' if Parent::PARIS_20_EME_POSTAL_CODE.include? postal_code

    return 'Plaisir' if Parent::PLAISIR_POSTAL_CODE.include? postal_code

    return 'Bondy' if Parent::BONDY_POSTAL_CODE.include? postal_code

    return 'Trappes' if Parent::TRAPPES_POSTAL_CODE.include? postal_code

    return 'Aulnay sous bois' if Parent::AULNAY_SOUS_BOIS_POSTAL_CODE.include? postal_code

    return 'Orleans' if Parent::ORELANS_POSTAL_CODE.include? postal_code

    return 'Montargis' if Parent::MONTARGIS_POSTAL_CODE.include? postal_code

    return 'Gien' if Parent::GIEN_POSTAL_CODE.include? postal_code

    return 'Pithiviers' if Parent::PITHIVIERS_POSTAL_CODE.include? postal_code

    return 'Villeneuve-la-Garenne' if Parent::VILLENEUVE_LA_GARENNE_POSTAL_CODE.include? postal_code

    return 'Mantes La Jolie' if Parent::MANTES_LA_JOLIE_POSTAL_CODE.include? postal_code

    return 'Asnières' if Parent::ASNIERES_POSTAL_CODE.include? postal_code

    return 'Gennevilliers' if Parent::GENNEVILLIERS_POSTAL_CODE.include? postal_code

  end

  def created_at_date
    h.l model.created_at.to_date, format: :default
  end

  def updated_at_date
    h.l model.updated_at.to_date, format: :default
  end

  def image_link_tag(**options)
    options.merge!(with_link: true, link_options: { target: '_blank'})
    h.image_tag_with_max_size **options
  end

end
