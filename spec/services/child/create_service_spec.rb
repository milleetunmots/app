require 'rails_helper'

RSpec.describe Child::CreateService do

  context "when params are valid" do
    it "creates a child" do
    end

    context "when registration_origin = 3" do
      it "adds 'form-pro' tag" do
      end

      it "sends sms at a specific time" do
      end
    end

    context "when registration_origin = 2" do
      it "adds 'form-2' tag" do
      end

      it "sends sms at a specific time" do
      end
    end

    context "when registration_origin is not 2 or 3" do
      it "adds 'form-2' site" do
      end

      it "does not send a sms" do
      end
    end

    context "when there are 2 parents" do
      it "sets should_contact_parent2 to true" do
      end
    end

    context "when only the second parent is filled" do
      it "sets the second parent as first parent" do
      end
    end

    context "when there are siblings" do
      it "creates siblings and add them on same child_support" do
      end
    end
  end

  context "when params are not valid" do
    context "when child attributes are not valid" do
      it "does not create child" do
      end

      context "when registration_origin = 2" do
        it "does not send sms" do
        end

        context "when registration_source = 'caf' and registration_source_details is blank" do
          it "returns validation error" do
          end
        end
      end

      context "when registration_origin = 3" do
        it "does not send sms" do
        end

        context "when registration_source = 'pmi' and pmi_detail is blank" do
          it "returns validation error" do
          end
        end
      end
    end

    context "when parents attributes are not valid" do
      it "does not create child" do
      end

      context "when registration_origin = 2" do
        it "does not send sms" do
        end
      end
    end

    context "when there are no parents" do
      it "does not create child" do
      end

      context "when registration_origin = 2" do
        it "does not send sms" do
        end
      end
    end

    context "when siblings are not valid" do
      it "does not create child" do
      end

      context "when registration_origin = 2" do
        it "does not send sms" do
        end
      end
    end
  end
end
