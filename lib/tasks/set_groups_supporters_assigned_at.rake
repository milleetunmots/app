# One-shot, à exécuter en production juste après le déploiement de supporters_assigned_at
namespace :groups do
  desc "Pose la date d'attribution sur les cohortes déjà démarrées ou déjà réparties qui n'en ont pas"
  task set_supporters_assigned_at: :environment do
    # Une cohorte répartie mais pas encore démarrée a des familles actives avec une accompagnante
    distributed_group_ids = Child.kept
                                 .where(group_status: 'active')
                                 .joins(:child_support)
                                 .where(child_supports: { discarded_at: nil })
                                 .where.not(child_supports: { supporter_id: nil })
                                 .select(:group_id)
    groups = Group.where(supporters_assigned_at: nil)
                  .where(started_at: ..Time.zone.today)
                  .or(Group.where(supporters_assigned_at: nil).where(id: distributed_group_ids))
    puts "#{groups.count} cohorte(s) à marquer comme attribuée(s)"

    marked_count = 0
    groups.find_each do |group|
      families = ChildSupport.kept.where(id: group.children.kept.where(group_status: 'active').select(:child_support_id))
      group.supporters_assigned_at = Time.zone.now
      group.save!(validate: false)
      marked_count += 1
      puts "  ##{group.id} #{group.name} (début : #{group.started_at}, familles avec accompagnante : #{families.where.not(supporter_id: nil).count}/#{families.count})"
    end

    puts "#{marked_count} cohorte(s) marquée(s) comme attribuée(s)"
  end
end
