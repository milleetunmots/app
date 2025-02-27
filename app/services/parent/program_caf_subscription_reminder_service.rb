class Parent::ProgramCafSubscriptionReminderService

  MESSAGE_V1 = "1001mots : Bonjour, Vous avez commencé votre inscription à 1001mots. Mais il vous reste une dernière étape : prendre rdv pour un appel avec une accompagnante 1001mots.\nPrenez rendez-vous dès aujourd'hui et commencez l'accompagnement dès la semaine prochaine ! https://form.typeform.com/to/w9H4beIF#cs=xxxxx&current_child_name=xxxxx&parent1_last_name=xxxxx&email=xxxxx&current_child_months=xxxxx&sc=xxxxx\nÀ très vite,\nL'équipe 1001mots".freeze
  MESSAGE_V2 = "1001mots : Bonjour, Vous avez commencé votre inscription à 1001mots, mais il vous reste une dernière étape : prendre rdv pour un appel avec une accompagnante 1001mots.\nPrenez rendez-vous dès aujourd'hui et commencez l'accompagnement dès la semaine prochaine ! https://calendly.com/d/cmtq-2md-6r5/1er-appel-1001mots?preview_source=et_card&month=2025-03\nÀ très vite,\nL’équipe 1001mots".freeze

  attr_reader :errors

  def initialize(version_one: true)
    @errors = []
    @children = Child.tagged_with('inscrit_via_caf_93').tagged_with('a_souscrit_caf_93', exclude: true).where(group_status: 'active', should_contact_parent1: true)
    @version_one = version_one
    @date = Time.zone.local(2025, 3, 5, 13, 30)
  end

  def call
    @children.find_each do |child|
      @parent = child.parent1
      @message = @version_one ? MESSAGE_V1 : MESSAGE_V2
      @message = @message.gsub('cs=xxxxx', "cs=#{@parent.id}")
      @message = @message.gsub('current_child_name=xxxxx', "current_child_name=#{child.first_name}")
      @message = @message.gsub('parent1_last_name=xxxxx', "parent1_last_name=#{@parent.last_name}")
      @message = @message.gsub('email=xxxxx', "email=#{@parent.email}")
      @message = @message.gsub('current_child_months=xxxxx', "current_child_months=#{child.months}")
      @message = @message.gsub('sc=xxxxx', "sc=#{@parent.security_code}")
      service = ProgramMessageService.new(
        @date.strftime('%d-%m-%Y'),
        @date.strftime('%H:%M'),
        ["parent.#{@parent.id}"],
        @message
      ).call
      @errors << { service: 'ProgramMessageService', parent_id: @parent.id, parent_phone_number: @parent.phone_number, errors: service.errors } if service.errors.any?
    end
    self
  end
end
