module BuzzExpert
  class ExportChildrenService

    attr_reader :errors, :csv

    def initialize(children:)
      @children = children
      @errors = []
    end

    def call
      if @children.without_parent_to_contact.any?
        @errors << "Certains enfants n'ont aucun parent à contacter"
        return self
      end

      objects = []
      latest_parent1_id = nil
      @children.order(:parent1_id).each do |child|
        next if latest_parent1_id == child.parent1_id
        latest_parent1_id = child.parent1_id

        if child.should_contact_parent1?
          objects << {
            parent: child.parent1,
            child: child
          }
        end

        if child.should_contact_parent2? && child.parent2
          objects << {
            parent: child.parent2,
            child: child
          }
        end
      end

      service = GenerateFileService.new(
        objects: objects
      ).call

      @errors = service.errors
      @csv = service.csv

      self
    end

  end
end
