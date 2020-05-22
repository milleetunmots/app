module BuzzExpert
  class ExportRedirectionUrlsService

    attr_reader :errors, :csv

    def initialize(redirection_urls:)
      @redirection_urls = redirection_urls
      @errors = []
    end

    def call
      objects = @redirection_urls.map do |redirection_url|
        {
          parent: redirection_url.parent,
          child: redirection_url.child,
          visit_url: Rails.application.routes.url_helpers.visit_redirection_url(
            id: redirection_url.id,
            security_code: redirection_url.security_code
          )
        }
      end

      variables = {
        visit_url: 'Lien court'
      }

      service = GenerateFileService.new(
        objects: objects,
        variables: variables
      ).call

      @errors = service.errors
      @csv = service.csv

      self
    end

  end
end
