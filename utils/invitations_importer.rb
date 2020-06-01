require_relative "./base_importer"

module Utils
  class InvitationsImporter < BaseImporter
    def initialize(opts = {})
      super(opts)
      @invitation_importer = ResourceImporter.new(
        site: @site,
        class_name: "GobiertoPeople::Invitation",
        relation: GobiertoPeople::Invitation.includes(:person).where(GobiertoPeople::Person.table_name => { site_id: @site.id })
      )
    end

    def import!
      @data.each do |row|
        puts "\n\n===================================="
        puts "Processing Row... #{ row.pretty_inspect }\n\n"
        person = @people_importer.import!(
          attributes: {
            name: row.cleaned_text("assisteix")
          }
        )
        department = @department_importer.import!(
          attributes: {
            name: row.cleaned_text("departament")
          }
        )

        not_persisted_resources = [person, department].select { |resource| resource.new_record? }
        if not_persisted_resources.blank?
          invitations_with_location = GobiertoPeople::Invitation.where('location @> ?', { name: row.cleaned_text("lloc") }.to_json)
          location = if invitations_with_location.exists?
                       invitations_with_location.first.location
                     else
                       row.location("lloc")
                     end
          @invitation_importer.import!(
            attributes: { external_id: row[":id"] },
            extra: { person_id: person.id,
                     organizer: row.cleaned_text("organitzador"),
                     title: row.cleaned_text("motiu"),
                     location: location,
                     start_date: row.datetime("data_inici"),
                     end_date: row.datetime("data_fi"),
                     department_id: department.id,
                     meta: { "organic_unit" => row.cleaned_text("unitat_org_nica"),
                             "expenses_financed_by_organizer" => row.cleaned_list("invitaci_a") } }
          )
        else
          puts "Some associated resources couldn't be resolved, preventing the creation of invitation with external_id: #{ row[":id"] }"
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
