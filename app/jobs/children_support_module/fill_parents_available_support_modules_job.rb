class ChildrenSupportModule
    class FillParentsAvailableSupportModulesJob < ApplicationJob
      def perform(group_id, fill_date, second_support_module)

        group = Group.includes(children: :child_support).find(group_id)

        # if second_support_module
        #     group.children


        # end

        
      end

    #   private

      def find_available_support_modules(child)
        child_age_range = case child.months
        when 0..5
            'less_than_five'
        when 6..11
            'six_to_eleven'
        when 12..17
            'twelve_to_seventeen'
        when 18..23
            'eighteen_to_twenty_three'
        else
            ''
        end

        bilingual_child = child.child_support.is_bilingual || false

        SupportModule.where("'#{child_age_range}' = ANY (age_ranges)").where(for_bilingual: bilingual_child)
      end

      def order_available_support_modules(child)
        support_modules = find_available_support_modules(child)
        available_support_modules_group_by_themes = {}
        available_support_modules_ordered = []

        SupportModule::THEME_LIST.each do |theme|
          # todo enlever le pluck(:id)
          available_support_modules_group_by_themes[theme] = support_modules.where('theme = ?', theme).pluck(:id).to_a
        end

        while !available_support_modules_group_by_themes.empty?
          available_support_modules_group_by_themes.reject! { |theme, support_modules_array| support_modules_array.blank? }

          available_support_modules_group_by_themes.each do |theme, support_modules_array|
            available_support_modules_ordered << support_modules_array.first
            support_modules_array.shift
          end
        end

        available_support_modules_ordered

        
      end


      def filling_child_support(child)
      end
    
    end
  end
  