namespace :sources do
  desc "Replace 'Je suis déjà inscrit à 1001mots' source with the first sibling's source and set re_enrollment flag"
  task fix_resubscribing: :environment do
    resubscribing_source = Source.find_by(name: 'Je suis déjà inscrit à 1001mots', channel: 'bao')

    unless resubscribing_source
      puts 'Source "Je suis déjà inscrit à 1001mots" (bao) not found. Aborting.'
      next
    end

    children_sources = ChildrenSource.where(source: resubscribing_source)
                                     .includes(child: { child_support: :children })

    total = children_sources.count
    updated = 0
    skipped = []

    puts "Found #{total} children with 'Je suis déjà inscrit à 1001mots' source"

    children_sources.find_each do |cs|
      child = cs.child
      next unless child

      child_support = child.child_support

      unless child_support
        skipped << { child_id: child.id, reason: 'no child_support' }
        next
      end

      first_sibling = child_support.children.order(:created_at).first
      first_sibling_cs = first_sibling&.children_source

      unless first_sibling_cs && first_sibling_cs.source_id != resubscribing_source.id
        skipped << { child_id: child.id, reason: 'first sibling has no source or same resubscribing source' }
        next
      end

      re_enrollment = child_support.ended_support?
      cs.update!(source: first_sibling_cs.source, re_enrollment: re_enrollment)
      updated += 1
    end

    puts "Updated: #{updated}/#{total}"
    if skipped.any?
      puts "Skipped #{skipped.size}:"
      skipped.each { |s| puts "  Child ##{s[:child_id]}: #{s[:reason]}" }
    end
  end
end
