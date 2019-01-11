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
            name: row.cleaned_text("Nom i cognoms"),
            position: row.cleaned_text("Càrrec")
          }
        )
        department = @department_importer.import!(
          attributes: {
            name: row.cleaned_text("Departament")
          }
        )

        not_persisted_resources = [person, department].select { |resource| resource.new_record? }
        if not_persisted_resources.blank?
          trips_with_destinations = GobiertoPeople::Invitation.where('meta @> ?', { original_destinations_attribute: row.cleaned_text("Destinació") }.to_json)
          destinations = if trips_with_destinations.exists?
                           trips_with_destinations.first.destinations_meta
                         else
                           row.locations_list("Destinació")
                         end
          @trip_importer.import!(
            attributes: { external_id: row["Id"] },
            extra: { person_id: person.id,
                     title: row.cleaned_text("Motiu"),
                     description: row.cleaned_text("Agenda"),
                     start_date: row.datetime("Inici viatge", fallback: row.datetime("Fi viatge")),
                     end_date: row.datetime("Fi viatge", fallback: row.datetime("Inici viatge")),
                     destinations_meta: destinations,
                     department_id: department.id,
                     meta: { "purpose" => row.raw_text("Motiu"),
                             "company" => row.raw_text("Comitiva"),
                             "food_expenses" => row.economic_amount("Dietes y manutenció"),
                             "accomodation_expenses" => row.economic_amount("Allotjament"),
                             "transport_expenses" => row.economic_amount("Transport"),
                             "other_expenses" => row.economic_amount("Altres despeses"),
                             "total_expenses" => row.economic_amount("Total despeses"),
                             "other_expenses_details" => row.raw_text("Especificació altres despeses"),
                             "comments" => row.raw_text("Observacions"),
                             "original_destinations_attribute" => row.cleaned_text("Destinació") } }
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
