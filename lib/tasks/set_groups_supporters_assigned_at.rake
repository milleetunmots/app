# One-shot, exécutée en production le JJ/MM/AAAA
namespace :groups do
  desc "Pose la date d'attribution sur les cohortes déjà démarrées qui n'en ont pas"
  task set_supporters_assigned_at: :environment do
    groups = Group.where(supporters_assigned_at: nil).where(started_at: ..Time.zone.today)
    puts "#{groups.count} cohorte(s) à marquer comme attribuée(s)"

    marked_count = 0
    groups.find_each do |group|
      group.supporters_assigned_at = Time.zone.now
      group.save!(validate: false)
      marked_count += 1
      puts "  ##{group.id} #{group.name} (début : #{group.started_at})"
    end

    puts "#{marked_count} cohorte(s) marquée(s) comme attribuée(s)"
  end
end
