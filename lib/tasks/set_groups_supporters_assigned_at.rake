# One-shot, exécutée en production le JJ/MM/AAAA
namespace :groups do
  desc 'Marque comme attribuées les cohortes dont au moins une fiche de suivi a déjà une accompagnante'
  task set_supporters_assigned_at: :environment do
    groups_with_supporter = Group.kept
                                 .where(supporters_assigned_at: nil)
                                 .where(id: Group.joins(:child_supports).where.not(child_supports: { supporter_id: nil }).select(:id))
    puts "#{groups_with_supporter.count} cohorte(s) à marquer comme attribuée(s)"

    marked_count = 0
    groups_with_supporter.find_each do |group|
      group.update_column(:supporters_assigned_at, Time.zone.now)
      marked_count += 1
      puts "  ##{group.id} #{group.name} (début : #{group.started_at})"
    end

    puts "#{marked_count} cohorte(s) marquée(s) comme attribuée(s)"
  end
end
