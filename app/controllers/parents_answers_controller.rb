class ParentsAnswersController < ApplicationController
  before_action :find_parent_child_and_survey
  skip_before_action :authenticate_admin_user!

  # GET /surveys/:survey_id/parents/:parent_id/answers/new
  def new
    # retrieve questions to be answered
    answered_question_ids = @parent.answers.joins(:question).where(questions: { survey_id: @survey.id }).pluck(:question_id)
    @question = @survey.questions.where.not(id: answered_question_ids).order(:order).first
    @child_first_name = @child.first_name
    @children = @child.siblings.where(group_id: @child.group_id)
    @books = ChildrenSupportModule.where(child_id: [@children.ids]).with_books.map(&:book).uniq

    # render completed view if all the questions are answered
    if @question.nil?
      @children_support_module = ChildrenSupportModule.where(child: @child, parent: @parent).last
      calc_service = ChildrenSupportModule::RemainingModulesService.new(
        parent_id: @parent.id,
        group_id: @child.group_id,
        children_support_module: @children_support_module
      ).call

      @max_remaining_module_count = calc_service.max_remaining_module_count
      @remaining_module_count = calc_service.remaining_module_count
      @module_index = calc_service.module_index
      render :completed and return
    end
  end

  # POST /surveys/:survey_id/parents/:parent_id/answers
  def create
    @question = Question.find(params[:question_id])
    @children = @child.siblings.where(group_id: @child.group_id)
    @options =
      if @question.with_open_ended_response
        []
      else
        ChildrenSupportModule.where(child_id: [@children.ids]).with_books.map(&:book).uniq.pluck(:id)
      end
    Answer.transaction do
      answer = Answer.create!(
        question: @question,
        response: params[:response],
        options: @options
      )
      ParentsAnswer.create!(parent: @parent, answer: answer)
    end

    # redirect to form
    # it will display the next question to be answered or the completed view
    redirect_to new_survey_parent_answer_path(
      @survey,
      @parent,
      sc: @parent.security_code,
      child_id: @child.id
    )
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_survey_parent_answer_path(
      @survey,
      @parent,
      sc: @parent.security_code,
      child_id: @child.id
    ), alert: 'Erreur lors de la sauvegarde, réessayez et contactez-nous si le problème persiste.'
  end

  private

  def find_parent_child_and_survey
    @survey = Survey.find(params[:survey_id])
    @parent = Parent.find(params[:parent_id])
    @child = Child.find(params[:child_id])
    @security_code = params[:sc] || params[:security_code]
    not_found and return if @parent.security_code != @security_code
    not_found and return unless @child.in?(@parent.children)
  end
end
