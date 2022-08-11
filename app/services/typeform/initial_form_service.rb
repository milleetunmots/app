module Typeform
  class InitialFormService
    include ApplicationHelper
    
    FIELD_IDS = {
      name: ENV['TYPEFORM_NAME'],
      child_count: ENV['TYPEFORM_CHILD_COUNT'],
      already_accompanied: ENV['TYPEFORM_ALREADY_ACCOMPANIED'],
      books_quantity: ENV['TYPEFORM_BOOKS_QUANTITY'],
      most_present_parent: ENV['TYPEFORM_MOST_PRESENT_PARENT'],
      other_parent_phone: ENV['TYPEFORM_OTHER_PARENT_PHONE'],
      other_parent_grade: ENV['TYPEFORM_OTHER_PARENT_GRADE'],
      other_parent_grade_country: ENV['TYPEFORM_OTHER_PARENT_GRADE_COUNTRY'],
      grade: ENV['TYPEFORM_GRADE'],
      grade_country: ENV['TYPEFORM_GRADE_COUNTRY'],
      reading_frequency: ENV['TYPEFORM_READING_FREQUENCY'],
      tv_frequency: ENV['TYPEFORM_TV_FREQUENCY'],
      is_bilingual: ENV['TYPEFORM_IS_BILINGUAL'],
      help_my_child_to_learn_is_important: ENV['TYPEFORM_HELP_MY_CHILD_TO_LEARN_IS_IMPORTANT'],
      would_like_to_do_more: ENV['TYPEFORM_WOULD_LIKE_TO_DO_MORE'],
      would_receive_advices: ENV['TYPEFORM_WOULD_LIKE_TO_RECEIVE_ADVICES'],
    }
    

    attr_reader :data

    def initialize(form_response)
      @child_support_id = form_response[:hidden][:child_support_id]
      @answers = form_response[:answers]
      @child_support = ChildSupport.find(@child_support_id)
      @parent1 = @child_support.parent1
      @parent2 = @child_support.parent2
      @data = {}
      # @typeform_id = form_response[:definition][:definition][:id]
      # @fields = form_response[:definition][:fields]
    end

    def call
      parse_answers
      update_parents
      update_child_support
      
      self
    end

    def parse_answers
      @answers.each do |answer|
        case answer[:field][:id]
        when FIELD_IDS[:name]
          @data[:name] = answer[:text] 
        when FIELD_IDS[:child_count]
          @data[:child_count] = answer[:choice][:label]
        when FIELD_IDS[:already_accompanied]
          @data[:already_accompanied] = answer[:choice][:label]
        when FIELD_IDS[:books_quantity]
          case answer[:choice][:label]
          when 0
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[0]
          when 1, 2, 3, 4, 5
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[1]
          when 6, 7, 8, 9, 10
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[2]
          else
            @data[:books_quantity] = ChildSupport::BOOKS_QUANTITY[3]
          end
        when FIELD_IDS[:most_present_parent]
          case answer[:choice][:label]
          when 'Moi'
            @data[:most_present_parent] = "#{@child_support.parent1.first_name} #{@child_support.parent1.last_name}" 
          when "Plutôt l'autre parent"
            @data[:most_present_parent] = @child_support.parent2 ? "#{@child_support.parent2.first_name child_support.parent2.last_name}" : "L'autre parent"
          when 'Les deux pareil !'
            @data[:most_present_parent] = 'Les deux parents' 
          else
            @data[:most_present_parent] = answer[:choice][:label]
          end
        when FIELD_IDS[:other_parent_phone]
          @data[:other_parent_phone] = Phonelib.parse(answer[:text]).e164
        when FIELD_IDS[:other_parent_grade]
          @data[:other_parent_grade] = answer[:choice][:label]
        when FIELD_IDS[:other_parent_grade_country]
          @data[:other_parent_grade_country] = answer[:choice][:label]
        when FIELD_IDS[:grade]
          @data[:grade] = answer[:choice][:label]
        when FIELD_IDS[:grade_country]
          @data[:grade_country] = answer[:choice][:label] == 'France'
        when FIELD_IDS[:reading_frequency]
          if answer[:choices][:labels] == ['Aucun']
            @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[0]
          else
            case answer[:choices][:labels].size
            when 1
              @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[1]
            when 2, 3, 4
              @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[2]
            when 5, 6, 7
              @data[:call1_reading_frequency] = ChildSupport::READING_FREQUENCY[3]
            end
          end
        when FIELD_IDS[:tv_frequency]
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
        when FIELD_IDS[:is_bilingual]
          @data[:is_bilingual] = answer[:choice][:label] == 'Oui'
        when FIELD_IDS[:help_my_child_to_learn_is_important]
          @data[:help_my_child_to_learn_is_important] = answer[:choice][:label]
        when FIELD_IDS[:would_like_to_do_more]
          @data[:would_like_to_do_more] = answer[:choice][:label]
        when FIELD_IDS[:would_receive_advices]
          @data[:would_receive_advices] = answer[:choice][:label]
        end
      end
    end

    def update_parents
      @parent1.update!(grade: @data[:grade], grade_country: @data[:grade_country])
      @parent2&.update!(g rade: @data[:other_parent_grade], grade_country: @data[:other_parent_grade_country])
    end

    def update_child_support
      informations = @child_support.important_information || ''
      informations += "\nNombre d'enfants: #{@data[:child_count]}" if @data[:child_count]
      informations += "\nÀ déjà été accompagné par 1001 mots" if @data[:already_accompanied]
      informations += "\n#{@data[:most_present_parent]} passe le plus de temps avec l'enfant" if @data[:most_present_parent]
      @child_support.important_information = informations

      unless @data[:other_parent_phone] == @parent1.phone_number || @data[:other_parent_phone] == @parent2&.phone_number
        @child_support.other_phone_number = @data[:other_parent_phone]
        @child_support.important_information += "\n#{@data[:other_parent_phone]}"
      end

      @child_support.update!(
        is_bilingual: @data[:is_bilingual],
        books_quantity: @data[:books_quantity],
        call1_reading_frequency: @data[:call1_reading_frequency],
        call1_tv_frequency: @data[:call1_tv_frequency],
        child_count: @data[:child_count],
        most_present_parent: @data[:most_present_parent],
        already_accompanied: @data[:already_accompanied]
      )
    end

  end
end