require "rails_helper"

RSpec.describe ChildrenSupportModulesController, type: :request do
  let!(:group) { FactoryBot.create(:group)}
  let(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let(:support_module_list) { FactoryBot.create_list(:support_module, 3) }
  let!(:children_support_module) do
    FactoryBot.create(
      :children_support_module,
      child: child,
      parent: child.parent1,
      support_module: nil,
      available_support_module_list: support_module_list.map(&:id)
    )
  end

  describe "#edit" do
    it "renders edit template" do
      get "/s/#{children_support_module.id}", params: { sc: child.parent1.security_code }
      expect(response).to render_template(:edit)
    end

    context "when no support module is selected" do
      it "displays all available support modules and provides the option to select one by clicking on 'Je laisse 1001mots choisir pour moi'" do
        get "/s/#{children_support_module.id}", params: { sc: child.parent1.security_code }
        expect(assigns(:support_module_selected)).to be nil
        expect(assigns(:support_modules)).to eq support_module_list
        expect(response.body).to include "Je laisse 1001mots choisir pour moi"
      end
    end

    context "when the security code in URL parameters is not a good" do
      it "fails" do
        get "/s/#{children_support_module.id}", params: { sc: nil }
        expect(response).to have_http_status(404)
      end
    end

    context "when a support module is already selected" do
      it "displays the support module selected" do
        children_support_module.update!(support_module: support_module_list.first)
        get "/s/#{children_support_module.id}", params: { sc: child.parent1.security_code }
        expect(assigns(:support_module_selected)).to eq support_module_list.first
        expect(response.body).to include 'Mauvaise nouvelle : il est trop tard pour choisir un thème mais'
      end
    end
  end

  describe "#update" do
    let(:params) { { children_support_module: { support_module_id: support_module_list.first.id } } }

    it "updates the children support module" do
      put children_support_module_path(children_support_module, sc: child.parent1.security_code), params: params
      children_support_module.reload

      expect(children_support_module.choice_date).to eq Time.zone.today
      expect(children_support_module.is_completed).to be true
      expect(children_support_module.support_module_id).to eq(support_module_list.first.id)
      expect(response).to redirect_to(updated_children_support_module_path(children_support_module.id, child_first_name: child.first_name, sc: child.parent1.security_code))
    end
  end

  describe "#updated" do
    it "displays thanks" do
      get "/children_support_modules/#{children_support_module.id}/updated", params: { child_first_name: child.first_name, sc: child.parent1.security_code }

      expect(assigns(:child_first_name)).to eq child.first_name
    end
  end
end
