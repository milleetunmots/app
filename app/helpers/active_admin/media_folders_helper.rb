module ActiveAdmin::MediaFoldersHelper

  def media_folder_parent_select_collection(child = nil)
    MediaFolder.where.not(id: child&.id).order(:name).map(&:decorate)
  end

end
