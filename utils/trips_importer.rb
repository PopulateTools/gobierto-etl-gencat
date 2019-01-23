require_relative "./base_importer"

module Utils
  class TripsImporter < BaseImporter
    def initialize(opts = {})
      super(opts)
      @trip_importer = ResourceImporter.new(
        site: @site,
        class_name: "GobiertoPeople::Trip",
        relation: GobiertoPeople::Trip.includes(:person).where(GobiertoPeople::Person.table_name => { site_id: @site.id })
      )
    end

    def import!
      @data.each do |row|
        puts "\n\n===================================="
        puts "Processing Row... #{ row.pretty_inspect }\n\n"
        person = @people_importer.import!(
          attributes: {
            name: row.cleaned_text("nom_i_cognoms"),
            position: row.cleaned_text("c_rrec")
          }
        )
        department = @department_importer.import!(
          attributes: {
            name: row.cleaned_text("departament")
          }
        )

        not_persisted_resources = [person, department].select { |resource| resource.new_record? }
        if not_persisted_resources.blank?
          trips_with_destinations = GobiertoPeople::Invitation.where('meta @> ?', { original_destinations_attribute: row.cleaned_text("destinaci") }.to_json)
          destinations = if trips_with_destinations.exists?
                           trips_with_destinations.first.destinations_meta
                         else
                           row.locations_list("destinaci")
                         end
          @trip_importer.import!(
            attributes: { external_id: row[":id"] },
            extra: { person_id: person.id,
                     title: row.cleaned_text("motiu"),
                     description: row.cleaned_text("agenda"),
                     start_date: row.datetime("inici_viatge", fallback: row.datetime("fi_viatge")),
                     end_date: row.datetime("fi_viatge", fallback: row.datetime("inici_viatge")),
                     destinations_meta: destinations,
                     department_id: department.id,
                     meta: { "purpose" => row.raw_text("motiu"),
                             "company" => row.raw_text("comitiva"),
                             "food_expenses" => row.economic_amount("dietes_i_manutenci"),
                             "accomodation_expenses" => row.economic_amount("allotjament"),
                             "transport_expenses" => row.economic_amount("transport"),
                             "other_expenses" => row.economic_amount("altres_despeses"),
                             "total_expenses" => row.economic_amount("total_despeses"),
                             "other_expenses_details" => row.raw_text("especificaci_altres_despeses"),
                             "comments" => row.raw_text("observacions"),
                             "original_destinations_attribute" => row.cleaned_text("destinaci") } }
          )
        else
          puts "Some associated resources couldn't be resolved, preventing the creation of trip with external_id: #{ row[":id"] }"
          error = { resource_attrs: row.pretty_inspect,
                    not_persisted_resources: not_persisted_resources.map(&:pretty_inspect) }
          @errors << error
        end
        puts "===================================="
      end

      super
    end
  end
end
