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

        SupportModule.where("'#{child_age_range}' = ANY (age_ranges)")
                    .where(for_bilingual: bilingual_child)
      end

      def order_available_support_modules(child)
      end


      def filling_child_support(child)
      end
    
    end
  end
  