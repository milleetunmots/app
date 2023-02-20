require "rails_helper"

RSpec.describe ChildrenController, type: :request do

  describe "#new" do
    it "renders new template" do
    end

    context "when URL is inscription1" do
      it "renders specific wording" do
      end

      it "sets session[:registration_origin]" do
      end
    end

    context "when URL is inscription2" do
      it "sets session[:registration_origin]" do
      end
    end

    context "when URL is inscription3" do
      it "sets session[:registration_origin]" do
      end
    end
  end

  describe "#create" do
    context "when params are valid" do
      it "redirects to created page" do
      end
    end

    context "when there are errors" do
      it "renders forms" do
      end
    end
  end

  describe "#created" do
    it "renders created template" do
    end

    context "when session[:registration_origin] is not set" do
      it "renders specific wording" do
      end

      it "renders widget" do
      end
    end

    context "when session[:registration_origin] = 1" do
      it "renders specific wording" do
      end

      it "renders widget" do
      end
    end

    context "when session[:registration_origin] = 2" do
      it "renders specific wording" do
      end

      it "does not render widget" do
      end
    end

    context "when session[:registration_origin] = 3" do
      it "renders specific wording" do
      end

      it "does not render widget" do
      end
    end
  end
end
