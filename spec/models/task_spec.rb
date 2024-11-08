# == Schema Information
#
# Table name: tasks
#
#  id            :bigint           not null, primary key
#  description   :text
#  discarded_at  :datetime
#  done_at       :date
#  due_date      :date
#  related_type  :string
#  status        :string
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assignee_id   :bigint
#  related_id    :bigint
#  reporter_id   :bigint
#  treated_by_id :bigint
#
# Indexes
#
#  index_tasks_on_assignee_id                  (assignee_id)
#  index_tasks_on_description                  (description)
#  index_tasks_on_discarded_at                 (discarded_at)
#  index_tasks_on_done_at                      (done_at)
#  index_tasks_on_due_date                     (due_date)
#  index_tasks_on_related_type_and_related_id  (related_type,related_id)
#  index_tasks_on_reporter_id                  (reporter_id)
#  index_tasks_on_title                        (title)
#  index_tasks_on_treated_by_id                (treated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => admin_users.id)
#  fk_rails_...  (reporter_id => admin_users.id)
#  fk_rails_...  (treated_by_id => admin_users.id)
#

require 'rails_helper'

RSpec.describe Task, type: :model do
  before(:each) do
    @task = FactoryBot.create(:task)
    @task_done = FactoryBot.create(:task, done_at: Date.yesterday)
    @task_not_done = FactoryBot.create(:task, done_at: nil)
    @user1 = FactoryBot.create(:admin_user)
    @user2 = FactoryBot.create(:admin_user)
  end

  describe "Validations" do
    context "succeed" do
      it "if the task have a title" do
        expect(FactoryBot.build_stubbed(:task)).to be_valid
      end
    end

    context "fail" do
      it "if the task doesn't have a title" do
        expect(FactoryBot.build_stubbed(:task, title: nil)).not_to be_valid
      end
    end
  end

  describe ".is_done?" do
    context "returns" do
      it "true if the task is done" do
        expect(@task_done.is_done?).to eq true
      end

      it "false if the task isn't done" do
        expect(@task_not_done.is_done?).to eq false
      end
    end
  end

  describe ".is_done = (v)" do
    context "sets done_at" do
      it "at the current time if v is empty, true, t or 1" do
        v = %w[true t 1].sample
        @task.is_done = v
        expect(@task.done_at.class).to be Date
      end

      it "at nil if the v isn't true, t or 1" do
        @task.is_done = false
        expect(@task.done_at.class).not_to be Date
      end
    end
  end

  describe "#todo" do
    context "returns" do
      it "tasks not done yet" do
        expect(Task.todo).to match_array [@task, @task_not_done]
      end
    end
  end

  describe "#done" do
    context "returns" do
      it "tasks done" do
        expect(Task.done).to eq [@task_done]
      end
    end
  end

  describe "#relating" do
    context "returns" do
      it "tasks related to model in parameter" do
        related_model = [:child, :group, :parent].sample
        related = FactoryBot.create(related_model)
        @task.update! related: related
        expect(Task.relating(related)).to eq [@task]
      end
    end
  end

  describe "#assigned_to" do
    context "returns" do
      it "tasks assigned to the user in parameter" do
        @task.assignee = @user1
        @task.save
        expect(Task.assigned_to(@user1)).to eq [@task]
      end
    end
  end

  describe "#not_assigned_to" do
    context "returns" do
      it "tasks not assigned to the user in parameter" do
        @task.assignee = @user2
        @task.save
        expect(Task.not_assigned_to(@user1)).to match_array [@task]
      end
    end
  end
end
