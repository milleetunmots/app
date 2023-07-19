module Bubble

  class BubbleService
    def initialize(bubble_model)
      @uri = URI("#{ENV.fetch('BUBBLE_DATA_API_URL')}/#{bubble_model}")
      @headers = {
        'Authorization' => "Bearer #{ENV.fetch('BUBBLE_TOKEN')}"
      }
    end

    protected

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
        if %w[video_type content_type].include? attribute
          data.update_column(attribute.to_sym, data_retrieved['type'])
          next
        end

        if attribute == 'child_session'
          data.update_column(attribute.to_sym, data_retrieved['child_id'])
          next
        end

        data.update_column(attribute.to_sym, data_retrieved[attribute.to_s])
      end
      data.save

      data
    end

    private

    def get_response(params)
      response = HTTP.headers(@headers).get(@uri, params: params)
      raise "Impossible de récupérer toutes les vidéos de bubble. Erreur lors de l'appel à l'API : #{response.code}" unless response.code == 200

      JSON.parse(response.body.to_s)['response']
    end
  end
end
