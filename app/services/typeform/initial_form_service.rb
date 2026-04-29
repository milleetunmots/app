module Typeform
  class InitialFormService < Typeform::TypeformService
    include ApplicationHelper

    FIELDS = {
      enrollment_reasons_baby: ENV['INITIAL_TYPEFORM_ENROLLMENT_REASONS_BABY'],
      enrollment_reasons_child: ENV['INITIAL_TYPEFORM_ENROLLMENT_REASONS_CHILD'],
      second_language: ENV['INITIAL_TYPEFORM_SECOND_LANGUAGE'],
      child_count: ENV['INITIAL_TYPEFORM_CHILD_COUNT'],
      already_working_with: ENV['INITIAL_TYPEFORM_ALREADY_WORKING_WITH'],
      books_quantity: ENV['INITIAL_TYPEFORM_BOOKS_QUANTITY'],
      most_present_parent: ENV['INITIAL_TYPEFORM_MOST_PRESENT_PARENT'],
      reading_frequency: ENV['INITIAL_TYPEFORM_READING_FREQUENCY'],
      tv_frequency: ENV['INITIAL_TYPEFORM_TV_FREQUENCY'],
      is_bilingual: ENV['INITIAL_TYPEFORM_IS_BILINGUAL'],
      other_parent_phone: ENV['INITIAL_TYPEFORM_OTHER_PARENT_PHONE']
    }.freeze

    attr_reader :data

    def initialize(form_response)
      super(form_response)
      @data = {}
      # @typeform_id = form_response[:definition][:definition][:id]
      # @fields = form_response[:definition][:fields]
    end

    def call
      verify_security_token
      return self unless @errors.empty?

      find_child_support
      return self unless @errors.empty?

      @parent1 = @child_support.parent1
      @parent2 = @child_support.parent2
      @respondent_is_parent1 = @security_token == @parent1&.security_token
      @child_first_name = @child_support.current_child&.first_name
      parse_answers
      update_child_support
      send_welcome_sms_if_submitted_in_time
      self
    end

    def strip_asterisks(text)
      text&.delete('*')&.strip
    end

    def parse_answers
      @answers.each do |answer|
        case answer[:field][:id]
        when FIELDS[:child_count]
          @data[:child_count] = answer[:choice][:label]
        when FIELDS[:already_working_with]
          @data[:already_working_with] = answer[:choice][:label]
        when FIELDS[:books_quantity]
          case answer[:choice][:label]
          when 'Aucun'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[0]
          when 'Entre 1 et 3'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[1]
          when 'Entre 4 et 10'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[2]
          when 'Plus de 10'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[3]
          end
        when FIELDS[:most_present_parent]
          label = strip_asterisks(answer[:choice][:label]) || answer[:choice][:other]
          respondent_label = @respondent_is_parent1 ? 'Le Parent 1' : 'Le Parent 2'
          other_label = @respondent_is_parent1 ? 'Le Parent 2' : 'Le Parent 1'
          case label
          when 'Moi'
            @data[:most_present_parent] = "#{respondent_label} passe le plus de temps avec #{@child_first_name}"
          when "Plutôt l'autre parent"
            @data[:most_present_parent] = "#{other_label} passe le plus de temps avec #{@child_first_name}"
          when 'Les deux pareil !'
            @data[:most_present_parent] = "Les 2 parents passent le plus de temps avec #{@child_first_name}"
          when 'Une assistante maternelle / nourrice'
            @data[:most_present_parent] = "Une assistante maternelle/nourrice passe le plus de temps avec #{@child_first_name}"
          when 'Le personnel de la crèche'
            @data[:most_present_parent] = "Le personnel de la crèche passe le plus de temps avec #{@child_first_name}"
          when 'Un autre membre de la famille'
            @data[:most_present_parent] = "Un autre membre de la famille passe le plus de temps avec #{@child_first_name}"
          else
            @data[:most_present_parent] = "Personne qui passe le plus de temps avec #{@child_first_name} : #{label}"
          end
        when FIELDS[:other_parent_phone]
          @data[:other_parent_phone] = Phonelib.parse(answer[:text]).e164
        when FIELDS[:reading_frequency]
          if answer[:choices][:labels] == ['Aucun']
            @data[:call0_reading_frequency] = ChildSupport::READING_FREQUENCY[0]
          else
            case answer[:choices][:labels].size
            when 1, 2
              @data[:call0_reading_frequency] = ChildSupport::READING_FREQUENCY[1]
            when 3, 4, 5, 6
              @data[:call0_reading_frequency] = ChildSupport::READING_FREQUENCY[2]
            when 7
              @data[:call0_reading_frequency] = ChildSupport::READING_FREQUENCY[3]
            end
          end
        when FIELDS[:tv_frequency]
          if answer[:choices][:labels] == ['Aucun']
            @data[:call0_tv_frequency] = ChildSupport::TV_FREQUENCY[0]
          else
            case answer[:choices][:labels].size
            when 1, 2
              @data[:call0_tv_frequency] = ChildSupport::TV_FREQUENCY[1]
            when 3, 4, 5, 6
              @data[:call0_tv_frequency] = ChildSupport::TV_FREQUENCY[2]
            when 7
              @data[:call0_tv_frequency] = ChildSupport::TV_FREQUENCY[3]
            end
          end
        when FIELDS[:is_bilingual]
          @data[:is_bilingual] =
            case answer[:choice][:label]
            when 'Oui'
              '0_yes'
            when 'Non'
              '1_no'
            else
              '2_no_information'
            end
        when FIELDS[:enrollment_reasons_baby], FIELDS[:enrollment_reasons_child]
          @data[:enrollment_reasons] = answer[:choices][:labels].map { |label| strip_asterisks(label) } if answer[:choices][:labels].present?
          @data[:enrollment_reasons] ||= []
          @data[:enrollment_reasons] << answer[:choices][:other] if answer[:choices][:other].present?
        when FIELDS[:second_language]
          @data[:second_language] = answer[:text]
        end
      end
    end

    def update_child_support
      informations = []
      informations << @child_support.important_information if @child_support.important_information
      informations << "Nombre d'enfants: #{@data[:child_count]}" if @data[:child_count]
      informations << "À déjà été accompagné par 1001mots" if @data[:already_working_with] == "Oui"
      informations << "#{@data[:most_present_parent]}" if @data[:most_present_parent]
      @child_support.important_information = informations.join("\n")

      unless @data[:other_parent_phone] == @parent1.phone_number || @data[:other_parent_phone] == @parent2&.phone_number
        @child_support.other_phone_number = @data[:other_parent_phone]
        @child_support.important_information += "\nAutre numéro de téléphone: #{@data[:other_parent_phone]}"
      end

      @child_support.is_bilingual = @data[:is_bilingual] if @data.key?(:is_bilingual)
      @child_support.books_quantity = @data[:books_quantity] if @data.key?(:books_quantity)
      @child_support.call0_reading_frequency = @data[:call0_reading_frequency] if @data.key?(:call0_reading_frequency)
      @child_support.call0_tv_frequency = @data[:call0_tv_frequency] if @data.key?(:call0_tv_frequency)
      @child_support.child_count = @data[:child_count] if @data.key?(:child_count)
      @child_support.most_present_parent = @data[:most_present_parent] if @data.key?(:most_present_parent)
      @child_support.already_working_with = @data[:already_working_with] if @data.key?(:already_working_with)
      @child_support.enrollment_reasons = @data[:enrollment_reasons] if @data.key?(:enrollment_reasons)
      @child_support.second_language = @data[:second_language] if @data.key?(:second_language)

      @errors << { message: 'ChildSupport saving failed', child_support_id: @child_support.id } unless @child_support.save
    end

    def send_welcome_sms_if_submitted_in_time
      child = @child_support.current_child
      return unless child&.created_at&.> 2.hours.ago

      message = "Bonjour, merci pour votre inscription à l'accompagnement de l'association 1001mots. Bienvenue, ça va bientôt démarrer !\nL'équipe 1001mots"
      SpotHit::SendSmsService.new([@parent1.id], Time.zone.now.to_i, message).call
    end
  end
end
