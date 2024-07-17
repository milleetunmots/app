class PaperTrail::ConvertVersionToJsonJob
  include Sidekiq::Worker
  
	def perform
		PaperTrail::Version.find_each do |version|
			version.update_columns(
				old_object: nil,
				old_object_changes: nil,
				object: version.old_object ? YAML.load(version.old_object) : nil,
				object_changes: version.old_object_changes ? YAML.load(version.old_object_changes) : nil
			)
		end
  end
end
