require "rails_helper"

RSpec.describe ChildSupportsController, type: :request do
  let(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'super_admin') }
  let(:group) { FactoryBot.create(:group) }
  let!(:first_child) { FactoryBot.create(:child) }
  let!(:second_child) { FactoryBot.create(:child, group: group, group_status: 'disengaged') }
  let!(:third_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let(:headers) { { 'Authorization' => ENV['API_TOKEN'] } }

  describe "#verify_caller_id" do
    context "when the request header has not the correct Authorization" do
      it "returns an unauthorized response with the error 'Invalid token'" do
        headers['Authorization'] = 'invalid token'
        get '/api/v1/child_support_count', params: { caller_id: supporter.id }, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid token')
      end
    end

    context "when the request header has not Authorization" do
      it "returns an unauthorized response with the error 'Token absent'" do
        get '/api/v1/child_support_count', params: { caller_id: supporter.id }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Token is required')
      end
    end
  end

  describe "GET #child_support_count" do
    context "when there is no caller_id parameter in the request" do
      it "returns a bad_request response with the error 'caller_id is required'" do
        get '/api/v1/child_support_count', headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('caller_id is required')
      end
    end

    context "when the caller_id is not caller's id" do
      it "returns a not_found response with the error 'Invalid caller_id'" do
        get '/api/v1/child_support_count', params: { caller_id: admin_user.id }, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Invalid caller_id')
      end
    end

    context "when the group_id is not group's id" do
      it "returns a not_found response with the error 'Invalid group_id'" do
        get '/api/v1/child_support_count',
              params: { caller_id: supporter.id, group_id: 1000009 },
              headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Invalid group_id')
      end
    end

    context "when there are a valid group_id" do
      it "returns a response with the number of child_supports supported by the caller in the group wich has group_id as its id" do
        second_child.child_support.supporter = supporter
        second_child.child_support.save
        third_child.child_support.supporter = supporter
        third_child.child_support.save
        get '/api/v1/child_support_count',
              params: { caller_id: supporter.id, group_id: group.id },
              headers: headers

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['total']).to eq(2)
        expect(JSON.parse(response.body)['active']).to eq(1)
        expect(JSON.parse(response.body)['not_active']).to eq(1)
      end
    end

    context "when there are no group_id" do
      it "returns a response with the number of child_supports supported by the caller" do
        first_child.group = group
        first_child.group_status = 'active'
        first_child.save
        first_child.child_support.supporter = supporter
        first_child.child_support.save
        second_child.child_support.supporter = supporter
        second_child.child_support.save
        get '/api/v1/child_support_count',
              params: { caller_id: supporter.id },
              headers: headers

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['total']).to eq(2)
        expect(JSON.parse(response.body)['active']).to eq(1)
        expect(JSON.parse(response.body)['not_active']).to eq(1)
      end
    end
  end
end
