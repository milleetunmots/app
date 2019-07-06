class CreateMissingInitialVersions < ActiveRecord::Migration[6.0]
  def change
    admin_user = AdminUser.first
    default_whodunnit = [admin_user.id, admin_user.email].join(':')

    [
      Child,
      Parent
    ].each do |klass|
      klass.find_each do |record|
        if record.versions.empty?
          PaperTrail.request.whodunnit = default_whodunnit
          record.paper_trail.save_with_version
        end
      end
    end
  end
end
