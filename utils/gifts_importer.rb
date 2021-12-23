require_relative "./base_importer"

module Utils
  class GiftsImporter < BaseImporter
    def initialize(opts = {})
      super(opts)
      @gift_importer = ResourceImporter.new(
        site: @site,
        class_name: "GobiertoPeople::Gift",
        relation: GobiertoPeople::Gift.includes(:person).where(GobiertoPeople::Person.table_name => { site_id: @site.id })
      )
    end

    def import!
      @data.each do |row|
        puts "\n\n===================================="
        puts "Processing Row... #{ row.pretty_inspect }\n\n"

        unless row.cleaned_text("tipologia") == "ALT CARREC"
          puts "Skipping not \"ALT CARREC\" person..."

          next
        end
        person = @people_importer.import!(
          attributes: {
            name: row.cleaned_text("rebut_per")
          }
        )
        not_persisted_resources = [person].select { |resource| resource.new_record? }
        if not_persisted_resources.blank?
          @gift_importer.import!(
            attributes: { external_id: row[":id"] },
            extra: { person_id: person.id,
                     name: row.cleaned_text("obsequi"),
                     reason: row.cleaned_text("destinat_a"),
                     date: row.datetime("data"),
                     meta: { "category_name" => row.cleaned_text("categor_a_obsequi"),
                             "event_name" => row.cleaned_text("en_ocasi_de"),
                             "delivered_by" => row.cleaned_text("lliurat_per") } }
          )
        else
          puts "Some associated resources couldn't be resolved, preventing the creation of gift with external_id: #{ row[":id"] }"
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
