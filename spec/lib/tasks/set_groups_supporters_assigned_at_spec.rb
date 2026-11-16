require 'rails_helper'
require 'rake'

RSpec.describe 'groups:set_supporters_assigned_at' do
  before(:all) do
    Rake.application.rake_require('tasks/set_groups_supporters_assigned_at', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  before { Rake::Task['groups:set_supporters_assigned_at'].reenable }

  def run_task
    travel_to(Time.zone.local(2026, 11, 30, 9)) do
      Rake::Task['groups:set_supporters_assigned_at'].invoke
    end
  end

  context "quand une cohorte sans date d'attribution a déjà démarré" do
    it "lui pose la date d'attribution du jour d'exécution" do
      group = FactoryBot.create(:group, started_at: Date.new(2026, 4, 13))

      expect { run_task }.to output(/1 cohorte\(s\) marquée\(s\)/).to_stdout

      expect(group.reload.supporters_assigned_at.to_date).to eq(Date.new(2026, 11, 30))
    end
  end

  context "quand une cohorte sans date d'attribution démarre le jour d'exécution" do
    it "lui pose la date d'attribution du jour d'exécution" do
      group = FactoryBot.create(:group, started_at: Date.new(2026, 11, 30))

      run_task

      expect(group.reload.supporters_assigned_at.to_date).to eq(Date.new(2026, 11, 30))
    end
  end

  context "quand une cohorte sans date d'attribution n'a pas encore démarré" do
    it "ne lui pose pas de date d'attribution" do
      group = FactoryBot.create(:group, started_at: Date.new(2026, 12, 7))

      run_task

      expect(group.reload.supporters_assigned_at).to be_nil
    end
  end

  context "quand une cohorte n'a pas de date de début" do
    it "ne lui pose pas de date d'attribution" do
      group = FactoryBot.create(:group)
      group.update_column(:started_at, nil)

      run_task

      expect(group.reload.supporters_assigned_at).to be_nil
    end
  end

  context "quand une cohorte a déjà une date d'attribution" do
    it 'conserve sa date' do
      group = FactoryBot.create(:group, started_at: Date.new(2026, 11, 16), supporters_assigned_at: Time.zone.local(2026, 11, 5, 10))

      run_task

      expect(group.reload.supporters_assigned_at).to eq(Time.zone.local(2026, 11, 5, 10))
    end
  end
end
