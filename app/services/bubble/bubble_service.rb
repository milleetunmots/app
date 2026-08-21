module Bubble

  class BubbleService
    include JsonResponseConcern

    def initialize(bubble_model)
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/#{bubble_model}")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
    end

    def all_datas(constraints = [])
      all_datas = []
      items_count = 0
      json_constraints = JSON.generate(constraints)
      loop do
        response = get_response({ cursor: items_count, constraints: json_constraints })

        all_datas.concat response['results']
        items_count += response['count']
        items_remaining_count = response['remaining']
        break if items_remaining_count.zero?
      end

      all_datas
    end

    def fill_data(model_table, data_retrieved, attributes)
      data = model_table.find_or_create_by(bubble_id: data_retrieved['_id'], created_date: data_retrieved['Created Date'])
      attributes.each do |attribute|
        data.update_column(attribute.to_sym, data_retrieved[attribute.to_s])
      end
      data.save

      data
    end

    private

    def get_response(params)
      response = HTTP.headers(@headers).get(@uri, params: params)
      body = parse_json_response(response)
      datas = body['response'] if body.is_a?(Hash)
      raise "Impossible de récupérer toutes les vidéos de bubble. Erreur lors de l'appel à l'API : #{json_error_message(response, body)}" if datas.blank?

      datas
    end
  end
end
