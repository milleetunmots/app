class Parent::SendDisengagementWarningAfterCallsService

  BUNDLES = [
    ['Après 1er KO · Appel 0', 'apres_premier_ko_appel0'],
    ['Après 1er KO · Appel 1', 'apres_premier_ko_appel1'],
    ['Après 1er KO · Appel 2', 'apres_premier_ko_appel2']
  ].freeze
  ENGAGEMENT_STATUSES = [ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished')].freeze

  attr_reader :errors

  def initialize(group_id, call_index)
    @call_index = call_index.to_i
    @group = Group.find(group_id)
    @errors = []
    @date = Time.zone.today
    @parent_ids = []
  end

  def call
    bundle = find_bundle
    return self unless bundle

    @child_supports = child_supports
    @parent_ids = @child_supports.map { |child_support| "parent.#{child_support.parent1.id}" }.uniq
    program_message(bundle)
    self
  end

  private

  def find_bundle
    name, key = BUNDLES.fetch(@call_index)
    bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
    @errors << Media::TextMessagesBundle.missing_message(name: name, key: key) unless bundle
    bundle
  end

  def program_message(bundle)
    link_id = bundle.redirection_target_id(1)
    service = ProgramMessageService.new(@date.strftime('%d-%m-%Y'), '19:00', @parent_ids, bundle.body1, bundle.rcs_media_id_to_send(1), link_id).call
    @errors << "Parent::SendDisengagementWarningAfterCallsService (group: #{@group.name}) : #{service.errors.uniq}" if service.errors.any?
  end

  def child_supports
    case @call_index
    when 0
      @group.child_supports
            .with_a_child_in_active_group
            .where.not('call0_status IN (?, ?)', ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished'))
    when 1
      @group.child_supports
            .with_a_child_in_active_group
            .where.not('call1_status IN (?, ?)', ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished'))
            .select { |child_support| child_support.call0_status.in? ENGAGEMENT_STATUSES }
    when 2
      @group.child_supports
            .with_a_child_in_active_group
            .where.not('call2_status IN (?, ?)', ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished'))
            .select { |child_support| child_support.call0_status.in?(ENGAGEMENT_STATUSES) && child_support.call1_status.in?(ENGAGEMENT_STATUSES) }
    else
      []
    end
  end
end
