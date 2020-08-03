class LinkRedirectionTargetsToMedia < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :redirection_targets, :medium, foreign_key: { to_table: :media }

    RedirectionTarget.find_each do |redirection_target|
      video = Media::Video.new(
        name: redirection_target.name,
        url: redirection_target.target_url
      )
      video.save!
      redirection_target.medium_id = video.id
      redirection_target.save!
    end

    remove_column :redirection_targets, :target_url
    remove_column :redirection_targets, :name
  end
end
