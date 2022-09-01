require 'rails_helper'

RSpec.describe Typeform::InitialFormService do
  let_it_be(:child, reload: true) { FactoryBot.create(:child)}


  describe 'webhooks' do
    it 'updating child_support with typeform data' do
      params = {"event_id": "01GA8VN3NDEWJYYWR5YSBWPTGG", "event_type": "form_response", "form_response": {"form_id": "XdWSv2hR", "token": "3rb2qiiarzoeecrhs9yt3rb2qiph84er", "landed_at": "2022-08-12T11:03:50Z", "submitted_at": "2022-08-12T11:04:58Z", "hidden": {"child_support_id": child.child_support.id}, "definition": {"id": "XdWSv2hR", "title": "Questionnaire initial 1001mots V2", "fields": [{"id": "typeform_name_id", "ref": "e9f81869-6960-4f8b-b039-a94c12b2b5cc", "type": "long_text", "title": "*Quel est le prénom de votre enfant inscrit à 1001mots ?*", "properties": {}}, {"id": "1Oomu9WSahmD", "ref": "6ffdf209-d13a-42b2-94ce-ab6ac26af5e1", "type": "picture_choice", "title": "*Selon vous, qu'est-ce qui est le plus utile pour aider **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** à parler ? *🤔", "properties": {}, "allow_multiple_selections": true, "choices": [{"id": "zJv5xTbCqJ1X", "label": "Quand je lui parle"}, {"id": "F6Iax9oLBBkx", "label": "Quand je lui chante des comptines"}, {"id": "GxuPAXJ7r2Au", "label": "Quand on joue ensemble"}, {"id": "S01UbvCGpJlt", "label": "Quand on regarde un livre ensemble"}]}, {"id": "typeform_child_count_id", "ref": "bdd39145-e370-454e-9431-c08f798122f2", "type": "multiple_choice", "title": "*Combien d'enfants avez-vous ?*", "properties": {}, "choices": [{"id": "RyMoJFmMZs3b", "label": "1"}, {"id": "xFR3EbFYQvXT", "label": "2"}, {"id": "0JGTJyorsigG", "label": "3"}, {"id": "m8ARDLC9L4ja", "label": "4"}, {"id": "5Pm78teW40p2", "label": "5"}, {"id": "onIHtEndDPi6", "label": "Plus de 5"}]}, {"id": "typeform_already_working_with_id", "ref": "7f6ff798-a790-4942-9fc1-ca00add15344", "type": "multiple_choice", "title": "*Avez-vous déjà été accompagné(e) par 1001mots pour un(e) autre de vos enfants ?*", "properties": {}, "choices": [{"id": "6DJI8PvZV6li", "label": "Non"}, {"id": "5qOFtlhgVL4G", "label": "Oui"}]}, {"id": "typeform_books_quantity_id", "ref": "cd2ec817-e02c-4722-aa20-7061133cc9c8", "type": "multiple_choice", "title": "*Combien avez-vous de livre(s) spécialement pour **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** à la maison ?*", "properties": {}, "choices": [{"id": "fIIg7irb0bMv", "label": "0"}, {"id": "IU0O5Q36QNDe", "label": "1"}, {"id": "RvoBiOMhJqcD", "label": "2"}, {"id": "l83E7M3WHRtq", "label": "3"}, {"id": "5bX3d4r4hR5S", "label": "4"}, {"id": "G9HUMOyW8bHO", "label": "5"}, {"id": "K1F6PlNeG4TA", "label": "6"}, {"id": "SnsvvXyFmnCI", "label": "7"}, {"id": "re678FhHgZYB", "label": "8"}, {"id": "XrDUZTnl9Otj", "label": "9"}, {"id": "goGeKQvfo0HY", "label": "10"}, {"id": "QPXIzrZBJqLh", "label": "Entre 11 et 20"}, {"id": "0eENVZNMQH8h", "label": "Plus de 20"}]}, {"id": "typeform_most_present_parent_id", "ref": "538fd9bd-435b-4634-954a-dd043c44c983", "type": "multiple_choice", "title": "*Qui passe le plus de temps avec **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** dans la journée en semaine ?*", "properties": {}, "allow_other_choice": true, "choices": [{"id": "X3OTdqKzGhi6", "label": "Moi"}, {"id": "szUamCC1wES7", "label": "Plutôt l'autre parent"}, {"id": "kMP3acq8PMF4", "label": "Les deux pareil !"}, {"id": "gN78yiVLN8If", "label": "Une assistante maternelle, nourrice"}, {"id": "fi0v4LCTm8UZ", "label": "Le personnel de la crèche"}, {"id": "uku3QlRYEpOl", "label": "Un autre membre de la famille"}]}, {"id": "typeform_other_parent_phone_id", "ref": "80e9d338-af20-400d-91bd-9f7d637b77eb", "type": "short_text", "title": "*Si vous ne l'avez pas déjà fait, vous pouvez nous donner le numéro de l'autre parent ici :*", "properties": {}}, {"id": "typeform_degree_id", "ref": "19ea80d8-6409-407f-b28d-e1d3fc1658c6", "type": "multiple_choice", "title": "*Quel est le dernier diplôme que vous avez obtenu ?*", "properties": {}, "allow_other_choice": true, "choices": [{"id": "FqdeBEgdo49l", "label": "Sans diplôme"}, {"id": "CeVO6QEgAUam", "label": "Brevet"}, {"id": "FnWt3y9OeVej", "label": "BEP ou CAP"}, {"id": "dqiaG4jcp6KJ", "label": "Bac"}, {"id": "T16alGALfs5R", "label": "Bac+1"}, {"id": "piMjOL0qHNFb", "label": "Bac+2"}, {"id": "LtEtvnz3WXye", "label": "Bac+3"}, {"id": "CrxxrsLwGayg", "label": "Bac+4"}, {"id": "FmnhX20wddXo", "label": "Bac+5 et plus"}]}, {"id": "typeform_degree_in_france_id", "ref": "3a6b26a4-91d0-45bd-8591-2c7878f3a0fb", "type": "multiple_choice", "title": "*Dans quel pays avez-vous obtenu votre diplôme ?*", "properties": {}, "choices": [{"id": "i7nYJquHdaTO", "label": "France"}, {"id": "UE6TnYWzguH4", "label": "Autre"}]}, {"id": "typeform_other_parent_degree_id", "ref": "84ca2645-94d5-49d9-8d76-0716a167dc2c", "type": "multiple_choice", "title": "*Quel est le dernier diplôme que l'autre parent a obtenu ?*", "properties": {}, "allow_other_choice": true, "choices": [{"id": "retKZMPIp8dJ", "label": "Sans diplôme"}, {"id": "NbikGWIwTvug", "label": "Brevet"}, {"id": "ZshskRf5Aqcm", "label": "BEP ou CAP"}, {"id": "7wSU5vXgyYsL", "label": "Bac"}, {"id": "DYyMXx6e6AAu", "label": "Bac+1"}, {"id": "9FHqQLTOSK6S", "label": "Bac+2"}, {"id": "ToVnlDy5Srmj", "label": "Bac+3"}, {"id": "204NK3JuiGfH", "label": "Bac+4"}, {"id": "InUsw7bTEbJS", "label": "Bac+5 et plus"}]}, {"id": "typeform_other_parent_degree_in_france_id", "ref": "9d784b83-4f4c-4310-ae6c-b7596e7a25e9", "type": "multiple_choice", "title": "*Dans quel pays l'autre parent a-t-il(elle) obtenu son diplôme ?*", "properties": {}, "choices": [{"id": "qvirwAVfx9Qb", "label": "France"}, {"id": "0KGR4V5Regoz", "label": "Autre"}]}, {"id": "typeform_reading_frequency_id", "ref": "f133e06f-c46f-43e2-a903-5f696fba8c9f", "type": "multiple_choice", "title": "*La semaine dernière, quels jours avez-vous regardé un livre avec **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** ? *📖 ", "properties": {}, "allow_multiple_selections": true, "choices": [{"id": "jwSWyDfwiXfh", "label": "Aucun"}, {"id": "7Dk1pOfsOhKX", "label": "Lundi"}, {"id": "h5KKIz3vqktz", "label": "Mardi"}, {"id": "m9BrNlG2kCdJ", "label": "Mercredi"}, {"id": "2oip33EZHOJR", "label": "Jeudi"}, {"id": "rZERvDYpCQho", "label": "Vendredi"}, {"id": "hbItaHjtKKyH", "label": "Samedi"}, {"id": "pXw7mk5sn3LF", "label": "Dimanche"}]}, {"id": "typeform_tv_frequency_id", "ref": "764d77ef-a8b4-490a-9bcc-31851208391b", "type": "multiple_choice", "title": "*La semaine dernière quels jours **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** a regardé la TV ou le téléphone plus de 5 minutes ?* 📺📳", "properties": {}, "allow_multiple_selections": true, "choices": [{"id": "opYbV5sVcvKA", "label": "Aucun"}, {"id": "Pqef2GoXYgBs", "label": "Lundi"}, {"id": "asjXiZbPJuyU", "label": "Mardi"}, {"id": "j9WCz5UsPK84", "label": "Mercredi"}, {"id": "HbG4Bz6Dgzoc", "label": "Jeudi"}, {"id": "LMcMehnPCn7P", "label": "Vendredi"}, {"id": "tBZso5BRas8d", "label": "Samedi"}, {"id": "jLa4l0fPsmJ1", "label": "Dimanche"}]}, {"id": "typeform_is_bilingual_id", "ref": "4d67f3e1-5e72-482e-97e9-d046a383a16f", "type": "multiple_choice", "title": "*Parlez-vous d'autres langues que le français avec **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** ?*", "properties": {}, "choices": [{"id": "gpkz3cDa6fYz", "label": "Oui"}, {"id": "cUaDy4om0ZdN", "label": "Non"}]}, {"id": "typeform_help_my_child_to_learn_id_important_id", "ref": "da960598-66e9-4a86-ae80-d7f492b48878", "type": "multiple_choice", "title": "Aider mon enfant à apprendre est important pour moi en ce moment", "properties": {}, "choices": [{"id": "bwYh4RJY9NZN", "label": "D'accord"}, {"id": "pisoc8khZ8Ct", "label": "Pas d'accord"}, {"id": "w3L04oyxeWb7", "label": "Je ne sais pas"}]}, {"id": "typeform_would_like_to_do_more_id", "ref": "8dcf90e4-1d26-46e6-876f-1fd664eb927d", "type": "multiple_choice", "title": "J'aimerais en faire encore plus pour l'aider à apprendre", "properties": {}, "choices": [{"id": "p2ts2CXR7p4y", "label": "D'accord"}, {"id": "oK4qCPCRT1bD", "label": "Pas d'accord"}, {"id": "gdfTWMDHCeqm", "label": "Je ne sais pas"}]}, {"id": "typeform_would_like_to_receive_advices_id", "ref": "c72278d9-cf0d-4ef9-898b-b744b5a6e979", "type": "multiple_choice", "title": "J'aimerais recevoir des conseils, des idées ou de l'aide pour apprendre des choses à mon enfant", "properties": {}, "choices": [{"id": "oC48itSLTcNH", "label": "D'accord"}, {"id": "mnjkv2W1aGwg", "label": "Pas d'accord"}, {"id": "QWtMA4TdyBpL", "label": "Je ne sais pas"}]}]}, "answers": [{"type": "text", "text": "Prenom", "field": {"id": "typeform_name_id", "type": "long_text", "ref": "e9f81869-6960-4f8b-b039-a94c12b2b5cc"}}, {"type": "choices", "choices": {"labels": ["Quand je lui parle", "Quand je lui chante des comptines", "Quand on joue ensemble", "Quand on regarde un livre ensemble"]}, "field": {"id": "1Oomu9WSahmD", "type": "picture_choice", "ref": "6ffdf209-d13a-42b2-94ce-ab6ac26af5e1"}}, {"type": "choice", "choice": {"label": "2"}, "field": {"id": "typeform_child_count_id", "type": "multiple_choice", "ref": "bdd39145-e370-454e-9431-c08f798122f2"}}, {"type": "choice", "choice": {"label": "Oui"}, "field": {"id": "typeform_already_working_with_id", "type": "multiple_choice", "ref": "7f6ff798-a790-4942-9fc1-ca00add15344"}}, {"type": "choice", "choice": {"label": "2"}, "field": {"id": "typeform_books_quantity_id", "type": "multiple_choice", "ref": "cd2ec817-e02c-4722-aa20-7061133cc9c8"}}, {"type": "choice", "choice": {"label": "Les deux pareil !"}, "field": {"id": "typeform_most_present_parent_id", "type": "multiple_choice", "ref": "538fd9bd-435b-4634-954a-dd043c44c983"}}, {"type": "text", "text": "0677889922", "field": {"id": "typeform_other_parent_phone_id", "type": "short_text", "ref": "80e9d338-af20-400d-91bd-9f7d637b77eb"}}, {"type": "choice", "choice": {"label": "Bac"}, "field": {"id": "typeform_degree_id", "type": "multiple_choice", "ref": "19ea80d8-6409-407f-b28d-e1d3fc1658c6"}}, {"type": "choice", "choice": {"label": "France"}, "field": {"id": "typeform_degree_in_france_id", "type": "multiple_choice", "ref": "3a6b26a4-91d0-45bd-8591-2c7878f3a0fb"}}, {"type": "choice", "choice": {"label": "Bac"}, "field": {"id": "typeform_other_parent_degree_id", "type": "multiple_choice", "ref": "84ca2645-94d5-49d9-8d76-0716a167dc2c"}}, {"type": "choice", "choice": {"label": "Autre"}, "field": {"id": "typeform_other_parent_degree_in_france_id", "type": "multiple_choice", "ref": "9d784b83-4f4c-4310-ae6c-b7596e7a25e9"}}, {"type": "choices", "choices": {"labels": ["Aucun"]}, "field": {"id": "typeform_reading_frequency_id", "type": "multiple_choice", "ref": "f133e06f-c46f-43e2-a903-5f696fba8c9f"}}, {"type": "choices", "choices": {"labels": ["Lundi", "Mardi", "Mercredi"]}, "field": {"id": "typeform_tv_frequency_id", "type": "multiple_choice", "ref": "764d77ef-a8b4-490a-9bcc-31851208391b"}}, {"type": "choice", "choice": {"label": "Oui"}, "field": {"id": "typeform_is_bilingual_id", "type": "multiple_choice", "ref": "4d67f3e1-5e72-482e-97e9-d046a383a16f"}}, {"type": "choice", "choice": {"label": "D'accord"}, "field": {"id": "typeform_help_my_child_to_learn_id_important_id", "type": "multiple_choice", "ref": "da960598-66e9-4a86-ae80-d7f492b48878"}}, {"type": "choice", "choice": {"label": "D'accord"}, "field": {"id": "typeform_would_like_to_do_more_id", "type": "multiple_choice", "ref": "8dcf90e4-1d26-46e6-876f-1fd664eb927d"}}, {"type": "choice", "choice": {"label": "D'accord"}, "field": {"id": "typeform_would_like_to_receive_advices_id", "type": "multiple_choice", "ref": "c72278d9-cf0d-4ef9-898b-b744b5a6e979"}}]}, "typeform": {"event_id": "01GA8VN3NDEWJYYWR5YSBWPTGG", "event_type": "form_response", "form_response": {"form_id": "XdWSv2hR", "token": "3rb2qiiarzoeecrhs9yt3rb2qiph84er", "landed_at": "2022-08-12T11:03:50Z", "submitted_at": "2022-08-12T11:04:58Z", "hidden": {"child_support_id": "38"}, "definition": {"id": "XdWSv2hR", "title": "Questionnaire initial 1001mots V2", "fields": [{"id": "typeform_name_id", "ref": "e9f81869-6960-4f8b-b039-a94c12b2b5cc", "type": "long_text", "title": "*Quel est le prénom de votre enfant inscrit à 1001mots ?*", "properties": {}}, {"id": "1Oomu9WSahmD", "ref": "6ffdf209-d13a-42b2-94ce-ab6ac26af5e1", "type": "picture_choice", "title": "*Selon vous, qu'est-ce qui est le plus utile pour aider **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** à parler ? *🤔", "properties": {}, "allow_multiple_selections": true, "choices": [{"id": "zJv5xTbCqJ1X", "label": "Quand je lui parle"}, {"id": "F6Iax9oLBBkx", "label": "Quand je lui chante des comptines"}, {"id": "GxuPAXJ7r2Au", "label": "Quand on joue ensemble"}, {"id": "S01UbvCGpJlt", "label": "Quand on regarde un livre ensemble"}]}, {"id": "typeform_child_count_id", "ref": "bdd39145-e370-454e-9431-c08f798122f2", "type": "multiple_choice", "title": "*Combien d'enfants avez-vous ?*", "properties": {}, "choices": [{"id": "RyMoJFmMZs3b", "label": "1"}, {"id": "xFR3EbFYQvXT", "label": "2"}, {"id": "0JGTJyorsigG", "label": "3"}, {"id": "m8ARDLC9L4ja", "label": "4"}, {"id": "5Pm78teW40p2", "label": "5"}, {"id": "onIHtEndDPi6", "label": "Plus de 5"}]}, {"id": "typeform_already_working_with_id", "ref": "7f6ff798-a790-4942-9fc1-ca00add15344", "type": "multiple_choice", "title": "*Avez-vous déjà été accompagné(e) par 1001mots pour un(e) autre de vos enfants ?*", "properties": {}, "choices": [{"id": "6DJI8PvZV6li", "label": "Non"}, {"id": "5qOFtlhgVL4G", "label": "Oui"}]}, {"id": "typeform_books_quantity_id", "ref": "cd2ec817-e02c-4722-aa20-7061133cc9c8", "type": "multiple_choice", "title": "*Combien avez-vous de livre(s) spécialement pour **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** à la maison ?*", "properties": {}, "choices": [{"id": "fIIg7irb0bMv", "label": "0"}, {"id": "IU0O5Q36QNDe", "label": "1"}, {"id": "RvoBiOMhJqcD", "label": "2"}, {"id": "l83E7M3WHRtq", "label": "3"}, {"id": "5bX3d4r4hR5S", "label": "4"}, {"id": "G9HUMOyW8bHO", "label": "5"}, {"id": "K1F6PlNeG4TA", "label": "6"}, {"id": "SnsvvXyFmnCI", "label": "7"}, {"id": "re678FhHgZYB", "label": "8"}, {"id": "XrDUZTnl9Otj", "label": "9"}, {"id": "goGeKQvfo0HY", "label": "10"}, {"id": "QPXIzrZBJqLh", "label": "Entre 11 et 20"}, {"id": "0eENVZNMQH8h", "label": "Plus de 20"}]}, {"id": "typeform_most_present_parent_id", "ref": "538fd9bd-435b-4634-954a-dd043c44c983", "type": "multiple_choice", "title": "*Qui passe le plus de temps avec **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** dans la journée en semaine ?*", "properties": {}, "allow_other_choice": true, "choices": [{"id": "X3OTdqKzGhi6", "label": "Moi"}, {"id": "szUamCC1wES7", "label": "Plutôt l'autre parent"}, {"id": "kMP3acq8PMF4", "label": "Les deux pareil !"}, {"id": "gN78yiVLN8If", "label": "Une assistante maternelle, nourrice"}, {"id": "fi0v4LCTm8UZ", "label": "Le personnel de la crèche"}, {"id": "uku3QlRYEpOl", "label": "Un autre membre de la famille"}]}, {"id": "typeform_other_parent_phone_id", "ref": "80e9d338-af20-400d-91bd-9f7d637b77eb", "type": "short_text", "title": "*Si vous ne l'avez pas déjà fait, vous pouvez nous donner le numéro de l'autre parent ici :*", "properties": {}}, {"id": "typeform_degree_id", "ref": "19ea80d8-6409-407f-b28d-e1d3fc1658c6", "type": "multiple_choice", "title": "*Quel est le dernier diplôme que vous avez obtenu ?*", "properties": {}, "allow_other_choice": true, "choices": [{"id": "FqdeBEgdo49l", "label": "Sans diplôme"}, {"id": "CeVO6QEgAUam", "label": "Brevet"}, {"id": "FnWt3y9OeVej", "label": "BEP ou CAP"}, {"id": "dqiaG4jcp6KJ", "label": "Bac"}, {"id": "T16alGALfs5R", "label": "Bac+1"}, {"id": "piMjOL0qHNFb", "label": "Bac+2"}, {"id": "LtEtvnz3WXye", "label": "Bac+3"}, {"id": "CrxxrsLwGayg", "label": "Bac+4"}, {"id": "FmnhX20wddXo", "label": "Bac+5 et plus"}]}, {"id": "typeform_degree_in_france_id", "ref": "3a6b26a4-91d0-45bd-8591-2c7878f3a0fb", "type": "multiple_choice", "title": "*Dans quel pays avez-vous obtenu votre diplôme ?*", "properties": {}, "choices": [{"id": "i7nYJquHdaTO", "label": "France"}, {"id": "UE6TnYWzguH4", "label": "Autre"}]}, {"id": "typeform_other_parent_degree_id", "ref": "84ca2645-94d5-49d9-8d76-0716a167dc2c", "type": "multiple_choice", "title": "*Quel est le dernier diplôme que l'autre parent a obtenu ?*", "properties": {}, "allow_other_choice": true, "choices": [{"id": "retKZMPIp8dJ", "label": "Sans diplôme"}, {"id": "NbikGWIwTvug", "label": "Brevet"}, {"id": "ZshskRf5Aqcm", "label": "BEP ou CAP"}, {"id": "7wSU5vXgyYsL", "label": "Bac"}, {"id": "DYyMXx6e6AAu", "label": "Bac+1"}, {"id": "9FHqQLTOSK6S", "label": "Bac+2"}, {"id": "ToVnlDy5Srmj", "label": "Bac+3"}, {"id": "204NK3JuiGfH", "label": "Bac+4"}, {"id": "InUsw7bTEbJS", "label": "Bac+5 et plus"}]}, {"id": "typeform_other_parent_degree_in_france_id", "ref": "9d784b83-4f4c-4310-ae6c-b7596e7a25e9", "type": "multiple_choice", "title": "*Dans quel pays l'autre parent a-t-il(elle) obtenu son diplôme ?*", "properties": {}, "choices": [{"id": "qvirwAVfx9Qb", "label": "France"}, {"id": "0KGR4V5Regoz", "label": "Autre"}]}, {"id": "typeform_reading_frequency_id", "ref": "f133e06f-c46f-43e2-a903-5f696fba8c9f", "type": "multiple_choice", "title": "*La semaine dernière, quels jours avez-vous regardé un livre avec **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** ? *📖 ", "properties": {}, "allow_multiple_selections": true, "choices": [{"id": "jwSWyDfwiXfh", "label": "Aucun"}, {"id": "7Dk1pOfsOhKX", "label": "Lundi"}, {"id": "h5KKIz3vqktz", "label": "Mardi"}, {"id": "m9BrNlG2kCdJ", "label": "Mercredi"}, {"id": "2oip33EZHOJR", "label": "Jeudi"}, {"id": "rZERvDYpCQho", "label": "Vendredi"}, {"id": "hbItaHjtKKyH", "label": "Samedi"}, {"id": "pXw7mk5sn3LF", "label": "Dimanche"}]}, {"id": "typeform_tv_frequency_id", "ref": "764d77ef-a8b4-490a-9bcc-31851208391b", "type": "multiple_choice", "title": "*La semaine dernière quels jours **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** a regardé la TV ou le téléphone plus de 5 minutes ?* 📺📳", "properties": {}, "allow_multiple_selections": true, "choices": [{"id": "opYbV5sVcvKA", "label": "Aucun"}, {"id": "Pqef2GoXYgBs", "label": "Lundi"}, {"id": "asjXiZbPJuyU", "label": "Mardi"}, {"id": "j9WCz5UsPK84", "label": "Mercredi"}, {"id": "HbG4Bz6Dgzoc", "label": "Jeudi"}, {"id": "LMcMehnPCn7P", "label": "Vendredi"}, {"id": "tBZso5BRas8d", "label": "Samedi"}, {"id": "jLa4l0fPsmJ1", "label": "Dimanche"}]}, {"id": "typeform_is_bilingual_id", "ref": "4d67f3e1-5e72-482e-97e9-d046a383a16f", "type": "multiple_choice", "title": "*Parlez-vous d'autres langues que le français avec **{{field:e9f81869-6960-4f8b-b039-a94c12b2b5cc}}** ?*", "properties": {}, "choices": [{"id": "gpkz3cDa6fYz", "label": "Oui"}, {"id": "cUaDy4om0ZdN", "label": "Non"}]}, {"id": "typeform_help_my_child_to_learn_id_important_id", "ref": "da960598-66e9-4a86-ae80-d7f492b48878", "type": "multiple_choice", "title": "Aider mon enfant à apprendre est important pour moi en ce moment", "properties": {}, "choices": [{"id": "bwYh4RJY9NZN", "label": "D'accord"}, {"id": "pisoc8khZ8Ct", "label": "Pas d'accord"}, {"id": "w3L04oyxeWb7", "label": "Je ne sais pas"}]}, {"id": "typeform_would_like_to_do_more_id", "ref": "8dcf90e4-1d26-46e6-876f-1fd664eb927d", "type": "multiple_choice", "title": "J'aimerais en faire encore plus pour l'aider à apprendre", "properties": {}, "choices": [{"id": "p2ts2CXR7p4y", "label": "D'accord"}, {"id": "oK4qCPCRT1bD", "label": "Pas d'accord"}, {"id": "gdfTWMDHCeqm", "label": "Je ne sais pas"}]}, {"id": "typeform_would_like_to_receive_advices_id", "ref": "c72278d9-cf0d-4ef9-898b-b744b5a6e979", "type": "multiple_choice", "title": "J'aimerais recevoir des conseils, des idées ou de l'aide pour apprendre des choses à mon enfant", "properties": {}, "choices": [{"id": "oC48itSLTcNH", "label": "D'accord"}, {"id": "mnjkv2W1aGwg", "label": "Pas d'accord"}, {"id": "QWtMA4TdyBpL", "label": "Je ne sais pas"}]}]}, "answers": [{"type": "text", "text": "Prenom", "field": {"id": "typeform_name_id", "type": "long_text", "ref": "e9f81869-6960-4f8b-b039-a94c12b2b5cc"}}, {"type": "choices", "choices": {"labels": ["Quand je lui parle", "Quand je lui chante des comptines", "Quand on joue ensemble", "Quand on regarde un livre ensemble"]}, "field": {"id": "1Oomu9WSahmD", "type": "picture_choice", "ref": "6ffdf209-d13a-42b2-94ce-ab6ac26af5e1"}}, {"type": "choice", "choice": {"label": "2"}, "field": {"id": "typeform_child_count_id", "type": "multiple_choice", "ref": "bdd39145-e370-454e-9431-c08f798122f2"}}, {"type": "choice", "choice": {"label": "Oui"}, "field": {"id": "typeform_already_working_with_id", "type": "multiple_choice", "ref": "7f6ff798-a790-4942-9fc1-ca00add15344"}}, {"type": "choice", "choice": {"label": "2"}, "field": {"id": "typeform_books_quantity_id", "type": "multiple_choice", "ref": "cd2ec817-e02c-4722-aa20-7061133cc9c8"}}, {"type": "choice", "choice": {"label": "Les deux pareil !"}, "field": {"id": "typeform_most_present_parent_id", "type": "multiple_choice", "ref": "538fd9bd-435b-4634-954a-dd043c44c983"}}, {"type": "text", "text": "0677889922", "field": {"id": "typeform_other_parent_phone_id", "type": "short_text", "ref": "80e9d338-af20-400d-91bd-9f7d637b77eb"}}, {"type": "choice", "choice": {"label": "Bac"}, "field": {"id": "typeform_degree_id", "type": "multiple_choice", "ref": "19ea80d8-6409-407f-b28d-e1d3fc1658c6"}}, {"type": "choice", "choice": {"label": "France"}, "field": {"id": "typeform_degree_in_france_id", "type": "multiple_choice", "ref": "3a6b26a4-91d0-45bd-8591-2c7878f3a0fb"}}, {"type": "choice", "choice": {"label": "Bac"}, "field": {"id": "typeform_other_parent_degree_id", "type": "multiple_choice", "ref": "84ca2645-94d5-49d9-8d76-0716a167dc2c"}}, {"type": "choice", "choice": {"label": "Autre"}, "field": {"id": "typeform_other_parent_degree_in_france_id", "type": "multiple_choice", "ref": "9d784b83-4f4c-4310-ae6c-b7596e7a25e9"}}, {"type": "choices", "choices": {"labels": ["Aucun"]}, "field": {"id": "typeform_reading_frequency_id", "type": "multiple_choice", "ref": "f133e06f-c46f-43e2-a903-5f696fba8c9f"}}, {"type": "choices", "choices": {"labels": ["Lundi", "Mardi", "Mercredi"]}, "field": {"id": "typeform_tv_frequency_id", "type": "multiple_choice", "ref": "764d77ef-a8b4-490a-9bcc-31851208391b"}}, {"type": "choice", "choice": {"label": "Oui"}, "field": {"id": "typeform_is_bilingual_id", "type": "multiple_choice", "ref": "4d67f3e1-5e72-482e-97e9-d046a383a16f"}}, {"type": "choice", "choice": {"label": "D'accord"}, "field": {"id": "typeform_help_my_child_to_learn_id_important_id", "type": "multiple_choice", "ref": "da960598-66e9-4a86-ae80-d7f492b48878"}}, {"type": "choice", "choice": {"label": "D'accord"}, "field": {"id": "typeform_would_like_to_do_more_id", "type": "multiple_choice", "ref": "8dcf90e4-1d26-46e6-876f-1fd664eb927d"}}, {"type": "choice", "choice": {"label": "D'accord"}, "field": {"id": "typeform_would_like_to_receive_advices_id", "type": "multiple_choice", "ref": "c72278d9-cf0d-4ef9-898b-b744b5a6e979"}}]}}}
      Typeform::InitialFormService.new(params[:form_response]).call
      child.child_support.reload
      child.parent1.reload

      expect(child.child_support.important_information).to eq("Nombre d'enfants: 2\nÀ déjà été accompagné par 1001 mots\nLes deux parents passent le plus de temps avec l'enfant\n+33677889922")
      expect(child.child_support.call1_reading_frequency).to eq("1_rarely")
      expect(child.child_support.books_quantity).to eq("2_one_to_five")
      expect(child.child_support.call1_tv_frequency).to eq("3_frequently")
      expect(child.child_support.most_present_parent).to eq("Les deux parents")
      expect(child.child_support.already_working_with).to eq(true)
      expect(child.child_support.child_count).to eq(2)
      expect(child.parent1.degree).to eq('Bac')
      expect(child.parent1.degree_in_france).to eq(true)
    end
  end
end
