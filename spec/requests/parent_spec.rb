
require 'rails_helper'

RSpec.describe ParentsController, type: :request do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let!(:parent) { FactoryBot.create(:parent) }

  describe '/parents/:id/current_child_source' do
    before do
      sign_in admin_user
    end

    context 'when parent has no current child' do
      it 'returns empty JSON' do
        get :"/parents/#{parent.id}/current_child_source"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context 'when parent has a current child' do
      let!(:source) { FactoryBot.create(:source) }
      let!(:group) { FactoryBot.create(:group, expected_children_number: 0, started_at: Time.zone.today.next_occurring(:monday)) }
      let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, children_source: ChildrenSource.create(source_id: source.id, details: 'Some details'), group_status: 'active') }



      it 'returns child source information' do
        get :"/parents/#{parent.id}/current_child_source"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({
                                        'group_id' => group.id,
                                        'source' => source.id,
                                        'source_details' => 'Some details'
                                      })
      end
    end
  end


  describe '/parents/:id' do
    let(:valid_attributes) do
      {
        mid_term_rate: 4,
        mid_term_reaction: "C'était super !",
        mid_term_speech: "Je recommande"
      }
    end

    context 'with valid params' do
      it 'updates the parent' do
        patch parent_path(parent), params: { parent: valid_attributes }

        expect(response).to have_http_status(:no_content)
        parent.reload
        expect(parent.mid_term_rate).to eq(4)
        expect(parent.mid_term_reaction).to eq("C'était super !")
        expect(parent.mid_term_speech).to eq("Je recommande")
      end
    end
  end
end
