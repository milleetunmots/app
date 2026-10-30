require 'rails_helper'

RSpec.describe ActiveAdmin::FlashTaskLinks do
  describe '.render' do
    it "remplace l'URL d'une tâche de l'application par un lien « Voir la tâche »" do
      html = described_class.render('Message bloqué. http://localhost:3000/admin/tasks/42')

      expect(html).to eq('Message bloqué. <a class="flash-task-link" href="http://localhost:3000/admin/tasks/42">Voir la tâche</a>')
      expect(html).to be_html_safe
    end

    it 'échappe le reste du message' do
      html = described_class.render("<script>alert(1)</script> l'envoi http://localhost:3000/admin/tasks/42")

      expect(html).to start_with('&lt;script&gt;alert(1)&lt;/script&gt; l&#39;envoi <a class=')
    end

    it "ne lie ni l'URL d'un autre hôte, ni une autre page de l'admin" do
      message = 'https://evil.example.com/admin/tasks/42 http://localhost:3000/admin/children/42'

      expect(described_class.render(message)).to eq(message)
    end

    it 'laisse intact un message déjà marqué sûr' do
      message = '<strong>Mis à la corbeille</strong>'.html_safe

      expect(described_class.render(message)).to eq(message)
    end

    it "laisse le message échappé, sans lien, quand l'hôte de l'application n'est pas configuré" do
      allow(Rails.application.routes.url_helpers).to receive(:admin_tasks_url).and_raise(ArgumentError, 'Missing host')

      expect(described_class.render('<b>Bloqué</b> http://localhost:3000/admin/tasks/42'))
        .to eq('&lt;b&gt;Bloqué&lt;/b&gt; http://localhost:3000/admin/tasks/42')
    end
  end
end
