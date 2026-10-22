ActiveAdmin.register_page "Mes statistiques d'appel" do
  menu false

  # Statistiques générales : le même dashboard pour toutes les accompagnantes, donc aucun paramètre dans le jeton.
  # Le filtrage individuel viendra avec un paramètre verrouillé côté Metabase.
  content title: "Mes statistiques d'appel" do
    embed = Metabase::GenerateEmbedUrlService.new(
      site_url: ENV.fetch('METABASE_URL', nil),
      secret_key: ENV.fetch('METABASE_SECRET_KEY', nil),
      dashboard_id: ENV.fetch('METABASE_DASHBOARD_ID', nil),
      params: {}
    ).call

    render partial: 'admin/caller_statistics/dashboard', locals: { iframe_url: embed.url }
  end
end
