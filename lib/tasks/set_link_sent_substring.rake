namespace :events do
	desc "Sauvegarder le résultat du substring des liens 1001mots présents dans les messages envoyés"
	task set_link_sent_substring: :environment do
		Event.sent_by_app_text_messages.where("body LIKE ?", "%https://app.1001mots.org/r/%").update_all(
			"link_sent_substring = (regexp_match(body, 'https://app\\.1001mots\\.org/r/([^/]+/..)'))[1]"
		)
	end
end
