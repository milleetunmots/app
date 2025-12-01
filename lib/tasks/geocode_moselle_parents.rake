namespace :parent do
  desc 'Add longitude and latitude to parents'
  task geocode: :environment do
    parents =
      Parent.joins(
        <<~SQL
          LEFT JOIN children AS children1 ON children1.parent1_id = parents.id
          LEFT JOIN children AS children2 ON children2.parent2_id = parents.id
          LEFT JOIN children_sources AS cs1 ON cs1.child_id = children1.id
          LEFT JOIN sources AS s1 ON s1.id = cs1.source_id
          LEFT JOIN children_sources AS cs2 ON cs2.child_id = children2.id
          LEFT JOIN sources AS s2 ON s2.id = cs2.source_id
        SQL
      ).where(
        's1.id = :source_id OR s2.id = :source_id',
        source_id: 4
      ).distinct
    parents.where(latitude: nil, longitude: nil).find_each do |parent|
      parent.geocode
      parent.save(validate: false)
    end
  end
end
