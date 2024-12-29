task create_surveys: :environment do
	# SONDAGE LORS DU CHOIX DE MODULE 5 SUR LES LIVRES RECUS PAR LES PARENTS
  survey_module_5_books = Survey.find_or_create_by(name: ENV['SURVEY_NAME_MODULE_FIVE_BOOKS'])
	Question.find_or_create_by(
		name: "Normalement, vous avez déjà reçu 4 livres pour {PRENOM_ENFANT}. Donnez-nous votre avis sur ces livres ! Quel est le livre que vous avez lu LE PLUS avec {PRENOM_ENFANT} ? 📚👍🏻",
		with_open_ended_response: false,
		uid: "books_module_five_most_read",
		order: 1,
		survey: survey_module_5_books
	)
	Question.find_or_create_by(
		name: "Et quel est le livre que vous avez lu LE MOINS avec {PRENOM_ENFANT} 📚👎🏻",
		with_open_ended_response: false,
		uid: "books_module_five_least_read",
		order: 2,
		survey: survey_module_5_books
	)
	Question.find_or_create_by(
		name: "Vous pouvez nous en dire plus sur le livre que vous avez moins lu ? Vous en avez pensé quoi ?",
		with_open_ended_response: true,
		uid: "books_module_five_least_read_text",
		order: 3,
		survey: survey_module_5_books
	)
end
