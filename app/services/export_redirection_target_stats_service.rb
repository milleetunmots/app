class ExportRedirectionTargetStatsService

  attr_reader :errors, :csv

  def initialize(redirection_target:)
    @redirection_target = redirection_target
    @errors = []
  end

  def call
    attributes = %i[
      id

      first_name
      last_name
      birthdate
      age
      gender
      letterbox_name
      address
      city_name
      postal_code

      parent1_gender
      parent1_first_name
      parent1_last_name
      parent1_phone_number_national
      should_contact_parent1

      parent2_gender
      parent2_first_name
      parent2_last_name
      parent2_phone_number_national
      should_contact_parent2

      registration_source
      registration_source_details

      group_name
      has_quit_group
    ]

    csv_options = ActiveAdmin.application.csv_options.clone
    bom = csv_options.delete :byte_order_mark
    csv_options[:headers] = true

    @csv = bom + CSV.generate(csv_options) do |csv|
      csv << attributes.map do |key|
        I18n.t("activerecord.attributes.child.#{key}")
      end + [
        'URL cible',
        "Nom de l'URL cible",
        'Lien cible',
        'Visité'
      ]
      @redirection_target.children.uniq.each do |child|
        child_has_visited = RedirectionUrl.where(
          redirection_target: @redirection_target,
          child: child
        ).with_visits.any?

        csv << attributes.map do |key|
          child.decorate.send(key)
        end + [
          @redirection_target.id,
          @redirection_target.name,
          @redirection_target.target_url,
          I18n.t(child_has_visited)
        ]
      end
    end

    self
  end

end
