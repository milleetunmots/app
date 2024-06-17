require 'rails_helper'

RSpec.describe ChildrenSupportModule::SelectModuleJob, type: :job do

  subject { described_class }

  let!(:group_with_module_zero) { FactoryBot.create(:group) }

  let!(:child_with_call3_status_ok) { FactoryBot.create(:child, group: group_with_module_zero, group_status: 'active') }
  let!(:child_with_call3_status_unfinished) { FactoryBot.create(:child, group: group_with_module_zero, group_status: 'active') }
  let!(:estimated_unengaged_child) { FactoryBot.create(:child, group: group_with_module_zero, group_status: 'active') }

  let!(:child_support_with_call3_status_ok) {
    FactoryBot.create(
      :child_support,
      current_child: child_with_call3_status_ok
    )
  }
  let!(:child_support_with_call3_status_unfinished) {
    FactoryBot.create(
      :child_support,
      current_child: child_with_call3_status_unfinished
    )
  }
  let!(:estimated_unengaged_child_support) {
    FactoryBot.create(
      :child_support,
      current_child: estimated_unengaged_child
    )
  }

  let!(:support_module) { FactoryBot.create(:support_module) }

  let!(:child_with_call3_status_ok_children_support_module) {
    FactoryBot.create(
      :children_support_module,
      child: child_with_call3_status_ok,
      parent: child_with_call3_status_ok.parent1,
      support_module: nil,
      available_support_module_list: [support_module]
    )
  }
  let!(:child_with_call3_status_unfinished_children_support_module) {
    FactoryBot.create(
      :children_support_module,
      child: child_with_call3_status_unfinished,
      parent: child_with_call3_status_unfinished.parent1,
      support_module: nil,
      available_support_module_list: [support_module]
    )
  }
  let!(:estimated_unengaged_child_children_support_module) {
    FactoryBot.create(
      :children_support_module,
      child: estimated_unengaged_child,
      parent: estimated_unengaged_child.parent1,
      support_module: nil,
      available_support_module_list: [support_module]
    )
  }

  describe '#perform' do
    module_zero_feature_start = DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])

    let!(:group_without_module_zero) {
      FactoryBot.create(
        :group,
        started_at: Faker::Date.in_date_period(
          year: module_zero_feature_start.year,
          month: module_zero_feature_start.month - 1
        ).next_occurring(:monday)
      )
    }

    let!(:child_wihtout_module_zero_with_call3_status_ok) {
      FactoryBot.create(
        :child,
        group: group_without_module_zero,
        group_status: 'active'
      )
    }
    let!(:child_wihtout_module_zero_with_call3_status_unfinished) {
      FactoryBot.create(
        :child,
        group: group_without_module_zero,
        group_status: 'active'
      )
    }
    let!(:estimated_unengaged_child_wihtout_module_zero) {
      FactoryBot.create(
        :child,
        group: group_without_module_zero,
        group_status: 'active'
      )
    }

    let!(:child_support_without_module_zero_with_call3_status_ok) {
      FactoryBot.create(
        :child_support,
        current_child: child_wihtout_module_zero_with_call3_status_ok
      )
    }
    let!(:child_support_without_module_zero_with_call3_status_unfinished) {
      FactoryBot.create(
        :child_support,
        current_child: child_wihtout_module_zero_with_call3_status_unfinished
      )
    }
    let!(:estimated_unengaged_child_support_without_module_zero) {
      FactoryBot.create(
        :child_support,
        current_child: estimated_unengaged_child_wihtout_module_zero
      )
    }

    let!(:child_wihtout_module_zero_with_call3_status_ok_children_support_module) {
      FactoryBot.create(
        :children_support_module,
        child: child_wihtout_module_zero_with_call3_status_ok,
        parent: child_wihtout_module_zero_with_call3_status_ok.parent1,
        support_module: nil,
        available_support_module_list: [support_module]
      )
    }
    let!(:child_wihtout_module_zero_with_call3_status_unfinished_children_support_module) {
      FactoryBot.create(
        :children_support_module,
        child: child_wihtout_module_zero_with_call3_status_unfinished,
        parent: child_wihtout_module_zero_with_call3_status_unfinished.parent1,
        support_module: nil,
        available_support_module_list: [support_module]
      )
    }
    let!(:estimated_unengaged_child_wihtout_module_zero_children_support_module) {
      FactoryBot.create(
        :children_support_module,
        child: estimated_unengaged_child_wihtout_module_zero,
        parent: estimated_unengaged_child_wihtout_module_zero.parent1,
        support_module: nil,
        available_support_module_list: [support_module]
      )
    }

    it 'add disengagement tag to children whose parents have not chosen module 3 and have not responded to call 3' do
      allow_any_instance_of(ChildSupport::SelectModuleService).to receive(:call)
      .and_return(ChildSupport::SelectModuleService.new(child_support_with_call3_status_ok, Date.today, '12:30', 5))

      child_support_with_call3_status_ok.update(call3_status: I18n.t('activerecord.attributes.child_support/call_status.1_ok'))
      child_support_without_module_zero_with_call3_status_ok.update(call3_status: I18n.t('activerecord.attributes.child_support/call_status.1_ok'))
      estimated_unengaged_child_support.update(call3_status: I18n.t('activerecord.attributes.child_support/call_status.2_ko'))
      estimated_unengaged_child_support_without_module_zero.update(call3_status: I18n.t('activerecord.attributes.child_support/call_status.2_ko'))
      child_support_with_call3_status_unfinished.update(call3_status: I18n.t('activerecord.attributes.child_support/call_status.5_unfinished'))
      child_support_without_module_zero_with_call3_status_unfinished.update(call3_status: I18n.t('activerecord.attributes.child_support/call_status.5_unfinished'))

      child_with_call3_status_ok_children_support_module.update(support_module: support_module, module_index: 4, is_completed: true)
      child_with_call3_status_unfinished_children_support_module.update(support_module: support_module, module_index: 4, is_completed: true)

      child_wihtout_module_zero_with_call3_status_ok_children_support_module.update(support_module: support_module, module_index: 3, is_completed: true)
      child_wihtout_module_zero_with_call3_status_unfinished_children_support_module.update(support_module: support_module, module_index: 3, is_completed: true)
      estimated_unengaged_child_wihtout_module_zero_children_support_module.update(support_module: support_module, module_index: 3, is_completed: true)

      ActiveJob::Base.queue_adapter = :test
      subject.perform_now(group_with_module_zero.id, Time.zone.now, 5)
      subject.perform_now(group_without_module_zero.id, Time.zone.now, 4)

      expect(estimated_unengaged_child_support.reload.tag_list).to match_array ["estime-desengage-t2"]
      expect(estimated_unengaged_child_support_without_module_zero.reload.tag_list).to match_array []
      expect(child_support_with_call3_status_ok.reload.tag_list).to match_array []
      expect(child_support_without_module_zero_with_call3_status_ok.reload.tag_list).to match_array []
      expect(child_support_with_call3_status_unfinished.reload.tag_list).to match_array []
      expect(child_support_without_module_zero_with_call3_status_unfinished.reload.tag_list).to match_array []
    end
  end
end
