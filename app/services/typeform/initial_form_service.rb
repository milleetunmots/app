module Typeform
  class InitialFormService < Typeform::TypeformService
    include ApplicationHelper

    FIELDS = {
      name: ENV['INITIAL_TYPEFORM_NAME'],
      child_count: ENV['INITIAL_TYPEFORM_CHILD_COUNT'],
      already_working_with: ENV['INITIAL_TYPEFORM_ALREADY_WORKING_WITH'],
      books_quantity: ENV['INITIAL_TYPEFORM_BOOKS_QUANTITY'],
      most_present_parent: ENV['INITIAL_TYPEFORM_MOST_PRESENT_PARENT'],
      other_parent_phone: ENV['INITIAL_TYPEFORM_OTHER_PARENT_PHONE'],
      other_parent_degree: ENV['INITIAL_TYPEFORM_OTHER_PARENT_DEGREE'],
      other_parent_degree_in_france: ENV['INITIAL_TYPEFORM_OTHER_PARENT_DEGREE_IN_FRANCE'],
      degree: ENV['INITIAL_TYPEFORM_DEGREE'],
      degree_in_france: ENV['INITIAL_TYPEFORM_DEGREE_IN_FRANCE'],
      reading_frequency: ENV['INITIAL_TYPEFORM_READING_FREQUENCY'],
      tv_frequency: ENV['INITIAL_TYPEFORM_TV_FREQUENCY'],
      is_bilingual: ENV['INITIAL_TYPEFORM_IS_BILINGUAL'],
      help_my_child_to_learn_is_important: ENV['INITIAL_TYPEFORM_HELP_MY_CHILD_TO_LEARN_IS_IMPORTANT'],
      would_like_to_do_more: ENV['INITIAL_TYPEFORM_WOULD_LIKE_TO_DO_MORE'],
      would_receive_advices: ENV['INITIAL_TYPEFORM_WOULD_LIKE_TO_RECEIVE_ADVICES'],
      parental_contexts: ENV['INITIAL_TYPEFORM_PARENTAL_CONTEXTS']
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
      parse_answers
      update_parents
      update_child_support
      self
    end

    def parse_answers
      @answers.each do |answer|
        # byebug
        case answer[:field][:id]
        when FIELDS[:name]
          @data[:name] = answer[:text]
        when FIELDS[:child_count]
          @data[:child_count] = answer[:choice][:label]
        when FIELDS[:already_working_with]
          @data[:already_working_with] = answer[:choice][:label]
        when FIELDS[:books_quantity]
          case answer[:choice][:label]
          when '0'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[0]
          when '1', '2', '3'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[1]
          when  '4', '5', '6', '7', '8', '9', '10'
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[2]
          else
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[3]
          end
        when FIELDS[:most_present_parent]
          case answer[:choice][:label]
          when 'Moi'
            @data[:most_present_parent] = "#{@child_support.parent1.first_name} #{@child_support.parent1.last_name} passe plus plus de temps avec l'enfant"
          when "Plutôt l'autre parent"
            parent_name = @child_support.parent2 ? "#{@child_support.parent2.first_name} #{@child_support.parent2.last_name}" : "L'autre parent"
            @data[:most_present_parent] = "#{parent_name} passe le plus de temps avec l'enfant"
          when 'Les deux pareil !'
            @data[:most_present_parent] = 'Les deux parents passent le plus de temps avec l\'enfant'
          else
            @data[:most_present_parent] = "#{answer[:choice][:label]} passe le plus de temps avec l'enfant"
          end
        when FIELDS[:other_parent_phone]
          @data[:other_parent_phone] = Phonelib.parse(answer[:text]).e164
        when FIELDS[:other_parent_degree]
          @data[:other_parent_degree] = answer[:choice][:label]
        when FIELDS[:other_parent_degree_in_france]
          @data[:other_parent_degree_in_france] = answer[:choice][:label]
        when FIELDS[:degree]
          @data[:degree] = answer[:choice][:label]
        when FIELDS[:degree_in_france]
          @data[:degree_in_france] = answer[:choice][:label] == 'France'
        when FIELDS[:reading_frequency]
          if answer[:choices][:labels] == ['Aucun']
            @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[0]
          else
            case answer[:choices][:labels].size
            when 1, 2
              @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[1]
            when 2, 3, 4, 5, 6
              @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[2]
            when 7
              @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[3]
            end
          end
        when FIELDS[:tv_frequency]
          if answer[:choices][:labels] == ['Aucun']
            @data[:call1_tv_frequency] = ChildSupport::TV_FREQUENCY[0]
          else
            case answer[:choices][:labels].size
            when 1, 2
              @data[:call1_tv_frequency] = ChildSupport::TV_FREQUENCY[1]
            when 3, 4, 5, 6
              @data[:call1_tv_frequency] = ChildSupport::TV_FREQUENCY[2]
            when 7
              @data[:call1_tv_frequency] = ChildSupport::TV_FREQUENCY[3]
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
        when FIELDS[:help_my_child_to_learn_is_important]
          @data[:help_my_child_to_learn_is_important] = answer[:choice][:label]
        when FIELDS[:would_like_to_do_more]
          @data[:would_like_to_do_more] = answer[:choice][:label]
        when FIELDS[:would_receive_advices]
          @data[:would_receive_advices] = answer[:choice][:label]
        when FIELDS[:parental_contexts]
          @data[:parental_contexts] = answer[:choices][:labels]
        end
      end
    end

    def update_parents
      @parent1.degree = @data[:degree]
      @parent1.degree_in_france = @data[:degree_in_france]
      @parent1.help_my_child_to_learn_is_important = @data[:help_my_child_to_learn_is_important]
      @parent1.would_like_to_do_more = @data[:would_like_to_do_more]
      @parent1.would_receive_advices = @data[:would_receive_advices]
      @errors << { message: 'Parent1 saving failed', parent1_id: @parent1.id } unless @parent1.save
      return unless @parent2

      @parent2&.degree = @data[:other_parent_degree]
      @parent2&.degree_in_france = @data[:other_parent_degree_in_france]
      @errors << { message: 'Parent2 saving failed', parent2_id: @parent2.id } unless @parent2.save
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

      @child_support.is_bilingual = @data[:is_bilingual]
      @child_support.books_quantity = @data[:books_quantity]
      @child_support.call1_reading_frequency = @data[:call1_reading_frequency]
      @child_support.call1_tv_frequency = @data[:call1_tv_frequency]
      @child_support.child_count = @data[:child_count]
      @child_support.most_present_parent = @data[:most_present_parent]
      @child_support.already_working_with = @data[:already_working_with]
      @child_support.parental_contexts = @data[:parental_contexts]

      @errors << { message: 'ChildSupport saving failed', child_support_id: @child_support.id } unless @child_support.save
    end
  end
end
