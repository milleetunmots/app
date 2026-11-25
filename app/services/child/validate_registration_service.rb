class Child::ValidateRegistrationService

  OVERSEAS_MESSAGE = "L'accompagnement 1001mots n'est pas encore disponible dans votre région. N'hésitez pas à suivre nos actualités sur notre site et notre page facebook !".freeze

  # present_parents : { 1 => attributs du parent 1, 2 => attributs du parent 2 }, réduit aux parents saisis.
  def initialize(child, present_parents:, parent1_postal_code:, source_id:)
    @child = child
    @present_parents = present_parents
    @parent1_postal_code = parent1_postal_code
    @source_id = source_id
  end

  def call
    @child.valid?
    if @present_parents.empty?
      @child.errors.add(:base, :invalid_parents, message: 'Au moins un parent est obligatoire.')
    else
      @present_parents.each { |index, attributes| validate_parent(index, attributes) }
    end
    @child.errors.add(:source, :invalid) unless Source.active.exists?(@source_id)
    @child.errors.add(:base, :invalid, message: OVERSEAS_MESSAGE) if @parent1_postal_code.to_i / 1000 == 97
    self
  end

  private

  def validate_parent(index, attributes)
    @child.errors.add("parent#{index}_first_name", :blank) if attributes[:first_name].blank?
    @child.errors.add("parent#{index}_last_name", :blank) if attributes[:last_name].blank?
    @child.errors.add("parent#{index}_phone_number_national", :blank) if attributes[:phone_number].blank?
    @child.errors.add("parent#{index}_gender", :invalid) unless attributes[:gender].present? && attributes[:gender].in?(Parent::GENDERS)
  end
end
