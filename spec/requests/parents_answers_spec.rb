require "rails_helper"

RSpec.describe ParentsAnswersController, type: :request do
  describe "#new" do
    it "affiche chaque livre dans une carte cliquable avec la nouvelle charte" do
      child = FactoryBot.create(:child, first_name: "Lina")
      book = FactoryBot.create(:book, title: "Petit Ours Brun")
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, book: book)
      survey = Survey.create!(name: "Sondage livres")
      Question.create!(survey: survey, name: "Quel livre {PRENOM_ENFANT} a-t-il préféré ?", uid: "livre_prefere", order: 1)

      get "/surveys/#{survey.id}/parents/#{child.parent1.id}/answers/new", params: { sc: child.parent1.security_code, child_id: child.id }
      page = Capybara.string(response.body)

      expect(page.find(".module-selection #mots-logo")[:src]).to include("registration/logo-1001mots")
      expect(page.find(".module-selection h1")).to have_text("Quel livre Lina a-t-il préféré ?")
      book_radio = page.find("label.module-card input[type='radio'][name='response'][value='#{book.id}']")
      expect(book_radio.ancestor("label.module-card")).to have_text("Petit Ours Brun")
      expect(page.find("label.module-card input[type='radio'][value='did_not_get_books']").ancestor("label.module-card")).to have_text("Je n’ai reçu aucun de ces livres")
      expect(page).to have_button("Continuer")
    end

    it "affiche la question ouverte dans une carte" do
      child = FactoryBot.create(:child, first_name: "Lina")
      survey = Survey.create!(name: "Sondage livres")
      Question.create!(survey: survey, name: "Un commentaire ?", uid: "commentaire", order: 1, with_open_ended_response: true)

      get "/surveys/#{survey.id}/parents/#{child.parent1.id}/answers/new", params: { sc: child.parent1.security_code, child_id: child.id }
      page = Capybara.string(response.body)

      expect(page.find(".module-selection-body")).to have_css(".module-selection-text textarea[name='response']")
    end
  end
end
