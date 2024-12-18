class ParentsAnswersController < ApplicationController
  skip_before_action :authenticate_admin_user!, only: :update

  def new
    current_child_id = params[:current_child_id]
    current_child = Child.find(current_child_id)
    survey = Survey.find(params[:survey_id])
    @survey_title = survey.title.gsub('{Prénom enfant}', current_child.first_name)
    @books = ChildrenSupportModule.where(child_id: current_child_id).where.not(book_id: nil).map(&:book)
  end
end
