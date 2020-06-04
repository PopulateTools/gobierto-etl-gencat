require_relative "./base_importer"

# En el people importer sacar la persona de
module Utils
  class ChargesImporter < BaseImporter
    def initialize(opts = {})
      super(opts)
      @charge_importer = ResourceImporter.new(
        site: @site,
        class_name: "GobiertoPeople::Charge",
        relation: GobiertoPeople::Charge.includes(:person).where(GobiertoPeople::Person.table_name => { site_id: @site.id })
      )
    end

    def import!
      @data.each do |row|
        puts "\n\n===================================="
        puts "Processing Row... #{ row.pretty_inspect }\n\n"
        person = @people_importer.import!(
          attributes: {
            name: row.cleaned_text("nom_complert")
          }
        )
        department = @department_importer.import!(
          attributes: {
            name: row.cleaned_text("desc_departament")
          }
        )

        not_persisted_resources = [person, department].select { |resource| resource.new_record? }
        if not_persisted_resources.blank?
          @charge_importer.import!(
            attributes: { external_id: row["id"] },
            extra: { person_id: person.id,
                     department_id: department.id,
                     name: row.cleaned_text("desc_carrec"),
                     start_date: row.datetime("data_inici_carrec"),
                     end_date: row.datetime("data_fi_carrec") }
          )
        else
          puts "Some associated resources couldn't be resolved, preventing the creation of charge with external_id: #{ row["id"] }"
          error = { resource_attrs: row.pretty_inspect,
                    resource_updated_at: row.datetime(":updated_at"),
                    not_persisted_resources: not_persisted_resources.map(&:pretty_inspect) }
          @errors << error
        end
        puts "===================================="
      end

      super
    end
  end
end
