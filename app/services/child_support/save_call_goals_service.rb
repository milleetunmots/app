class ChildSupport::SaveCallGoalsService

  # Valeurs du select « Modèle de SMS » du formulaire Message qui désignent une petite mission.
  TEMPLATES = %w[call0_goals call1_goals call2_goals call3_goals call3_goals_observing call3_goals_speaking].freeze

  attr_reader :errors

  def self.template?(template)
    template.in?(TEMPLATES)
  end

  # overwrite: false laisse en place une PM déjà présente, même identique : la
  # relance d'un envoi bloqué ne doit pas remplacer ce que la fiche affiche déjà.
  def initialize(child_support:, template:, message:, call_goal: nil, overwrite: true)
    @child_support = child_support
    @template = template
    @message = message
    @call_goal = call_goal
    @overwrite = overwrite
    @skipped = false
    @errors = []
  end

  def call
    unless self.class.template?(@template)
      @errors << { message: "Modèle de petite mission inconnu : #{@template}", context: { template: @template } }
      return self
    end
    unless @child_support
      @errors << { message: 'Aucune fiche de suivi pour enregistrer la petite mission', context: { template: @template } }
      return self
    end

    goals_column = "#{call_goals}_sms"
    if !@overwrite && @child_support.send(goals_column).present?
      @skipped = true
      return self
    end

    @child_support.paper_trail.update_column(goals_column.to_sym, @message)
    @child_support.paper_trail.update_column(:call0_goal_sent, @call_goal) if @template == 'call0_goals'
    self
  end

  # Vrai quand la PM n'a pas été écrite parce que la case était déjà remplie.
  def skipped?
    @skipped
  end

  private

  # Les deux variantes de l'appel 3 partagent la case de l'appel 3.
  def call_goals
    @template.in?(%w[call3_goals_speaking call3_goals_observing]) ? 'call3_goals' : @template
  end
end
