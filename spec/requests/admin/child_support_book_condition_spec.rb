require 'rails_helper'

RSpec.describe 'Admin child support book condition', type: :request do
  let!(:group) { FactoryBot.create(:group) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:children_support_module, child: child, parent: child.parent1, book: book) }
  let(:child_support) { child.child_support }

  def sign_in_as(user_role)
    admin_user = FactoryBot.create(:admin_user, user_role: user_role)
    child_support.update!(supporter: admin_user) if user_role.in?(%w[caller animator])
    sign_in admin_user
    admin_user
  end

  def book_condition_select
    get "/admin/child_supports/#{child_support.id}/edit?r=true"
    Nokogiri::HTML(response.body).at_css('select.book-select')
  end

  def submit_book_condition(value, important_information: nil)
    attributes = { children_support_modules_attributes: { '0' => { id: support_module.id, book_condition: value } } }
    attributes[:important_information] = important_information if important_information
    patch "/admin/child_supports/#{child_support.id}", params: { child_support: attributes }
  end

  %w[super_admin contributor].each do |user_role|
    context "en tant que #{user_role}" do
      before { sign_in_as(user_role) }

      it "propose l'option « Non envoyé »" do
        expect(book_condition_select.css('option').pluck('value')).to include('not_sent')
      end

      it 'laisse le select actif quand le livre est « Non envoyé »' do
        support_module.update!(book_condition: 'not_sent')

        expect(book_condition_select['disabled']).to be_nil
      end

      it 'enregistre le passage à « Non envoyé »' do
        submit_book_condition('not_sent')

        expect(support_module.reload.book_condition).to eq('not_sent')
      end

      it 'enregistre le retrait de « Non envoyé »' do
        support_module.update!(book_condition: 'not_sent')

        submit_book_condition('')

        expect(support_module.reload.book_condition).to be_blank
      end
    end
  end

  %w[reader caller animator].each do |user_role|
    context "en tant que #{user_role}" do
      before { sign_in_as(user_role) }

      it "ne propose pas l'option « Non envoyé »" do
        options = book_condition_select.css('option').pluck('value')

        expect(options).to include('not_received', 'damaged')
        expect(options).not_to include('not_sent')
      end

      it 'affiche « Non envoyé » dans un select désactivé quand le livre est « Non envoyé »' do
        support_module.update!(book_condition: 'not_sent')
        select = book_condition_select

        expect(select['disabled']).to be_present
        expect(select.at_css('option[selected]')['value']).to eq('not_sent')
      end

      it 'ignore le passage à « Non envoyé » sans bloquer le reste de la fiche' do
        submit_book_condition('not_sent', important_information: 'Rappeler mardi')

        expect(support_module.reload.book_condition).to be_blank
        expect(child_support.reload.important_information).to eq('Rappeler mardi')
      end

      it 'ignore le retrait de « Non envoyé »' do
        support_module.update!(book_condition: 'not_sent')

        submit_book_condition('not_received')

        expect(support_module.reload.book_condition).to eq('not_sent')
      end

      it 'enregistre toujours « Non reçu »' do
        submit_book_condition('not_received')

        expect(support_module.reload.book_condition).to eq('not_received')
      end

      # Rails accepte aussi les attributs imbriqués sous forme de tableau
      it 'ignore le passage à « Non envoyé » envoyé sous forme de tableau' do
        patch "/admin/child_supports/#{child_support.id}",
              params: { child_support: { important_information: 'Rappeler mardi',
                                         children_support_modules_attributes: [{ id: support_module.id, book_condition: 'not_sent' }] } }

        expect(support_module.reload.book_condition).to be_blank
        expect(child_support.reload.important_information).to eq('Rappeler mardi')
      end
    end
  end

  describe 'alerte de renvoi' do
    before do
      BookShipmentDate.create!(date: Date.current + 10.days)
      sign_in_as('contributor')
    end

    it 'mentionne les livres non envoyés' do
      support_module.update!(book_condition: 'not_sent')

      get "/admin/child_supports/#{child_support.id}/edit?r=true"

      expect(response.body).to include("Les livres non reçus / défectueux / non envoyés seront renvoyés le #{(Date.current + 10.days).strftime('%d/%m/%Y')}")
    end
  end
end
