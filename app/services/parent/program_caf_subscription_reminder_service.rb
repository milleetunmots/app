class Parent::ProgramCafSubscriptionReminderService

  MESSAGE_V1 = "1001mots Bonjour, Vous avez commencé votre inscription à 1001mots, mais il vous reste une dernière étape : prendre rdv pour un appel avec une accompagnante 1001mots.\nPrenez rendez-vous dès aujourd'hui et commencez l'accompagnement dès la semaine prochaine ! https://form.typeform.com/to/w9H4beIF#cs=xxxxx&ccn=xxxxx&pln=xxxxx&email=xxxxx&ccm=xxxxx&sc=xxxxx\nÀ très vite,\nL'équipe 1001mots".freeze
  MESSAGE_V2 = "1001mots Bonjour, Vous avez commencé votre inscription à 1001mots, mais il vous reste une dernière étape : prendre rdv pour un appel avec une accompagnante 1001mots.\nPrenez rendez-vous dès aujourd'hui et commencez l'accompagnement dès la semaine prochaine ! https://calendly.com/d/cmtq-2md-6r5/1er-appel-1001mots?preview_source=et_card&month=2025-03\nÀ très vite,\nL’équipe 1001mots".freeze

  attr_reader :errors

  def initialize(date_time:, message_v1: true)
    @errors = []
    @children = Child.tagged_with('inscrit_via_caf_93').tagged_with('a_souscrit_caf_93', exclude: true).where(group_status: 'active', should_contact_parent1: true)
    @message_v1 = message_v1
    @date = date_time
  end

  def call
    @children.find_each do |child|
      @parent = child.parent1
      @message = @message_v1 ? MESSAGE_V1 : MESSAGE_V2
      @message = @message.gsub('cs=xxxxx', "cs=#{@parent.id}")
      @message = @message.gsub('ccn=xxxxx', "ccn=#{child.first_name}")
      @message = @message.gsub('pln=xxxxx', "pln=#{@parent.last_name}")
      @message = @message.gsub('email=xxxxx', "email=#{@parent.email}")
      @message = @message.gsub('ccm=xxxxx', "ccm=#{child.months}")
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
