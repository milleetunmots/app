
require 'rails_helper'

RSpec.describe Typeform::MidwayFormService do
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let!(:child_support) { child.child_support }

  describe '#call' do
    context 'with valid answers' do
      let(:answers) do
        [
          {
            field: { id: ENV['MID_TERM_TYPEFORM_RATE_FIELD'] },
            number: 4
          },
          {
            field: { id: ENV['MID_TERM_TYPEFORM_REACTION_FIELD'] },
            choice: { label: "Très satisfait" }
          },
          {
            field: { id: ENV['MID_TERM_TYPEFORM_SPEECH_FIELD'] },
            text: "C'était une super expérience"
          }
        ]
      end
      let(:service) do
        Typeform::MidwayFormService.new(
          answers: answers,
          hidden: {
            st: parent.security_token
          }
        )
      end

      it 'updates parent and child_support' do
        result = service.call

        expect(result.errors).to be_empty

        parent.reload
        expect(parent.mid_term_rate).to eq(4)
        expect(parent.mid_term_reaction).to eq("Très satisfait")
        expect(parent.mid_term_speech).to eq("C'était une super expérience")

        child_support.reload
        expect(child_support.parent_mid_term_rate).to eq(4)
        expect(child_support.parent_mid_term_reaction).to eq("Très satisfait")
      end
    end

    context 'when parent or child_support is not found' do
      let(:answers) { [] }
      let(:service) do
        Typeform::MidwayFormService.new(
          answers: answers,
          hidden: {
            st: "#{parent.security_token}x"
          }
        )
      end

      it 'returns error' do
        result = service.call
        expect(result.errors).not_to be_empty
      end
    end
  end
end
