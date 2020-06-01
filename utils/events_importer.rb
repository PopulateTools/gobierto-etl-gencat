require_relative "./base_importer"

module Utils
  class EventsImporter < BaseImporter
    def import!
      @data.each do |row|
        puts "\n\n===================================="
        puts "Processing Row... #{ row.pretty_inspect }\n\n"
        person = @people_importer.import!(
          attributes: {
            name: row.cleaned_text("alt_c_rrec")
          }
        )
        interest_group = @interest_group_importer.import!(
          attributes: {
            name: row.cleaned_text("grup_d_inter_s"),
          },
          extra: {
            meta: { "status" => row.cleaned_text("inscripci_al_rgi"),
                    "registry_name" => row.cleaned_text("nom_registre_grup_inter_s"),
                    "registry_id" => row.cleaned_text("n_mero_de_rgi") }
          }
        )
        not_persisted_resources = [person, interest_group].select { |resource| resource.new_record? }
        if not_persisted_resources.blank?
          start_date = row.datetime("data") || row.datetime(":created_at") # If data (date) is nil, use the created_at attribute
          start_date = start_date.change(year: row.datetime(":created_at").year) if start_date.year < 2010
          end_date = 1.hour.since(start_date)
          attributes = { external_id: row[":id"],
                         starts_at: start_date,
                         ends_at: end_date,
                         title_translations: { "ca" => row.cleaned_text("tema") },
                         site_id: @site.id,
                         person_id: person.id,
                         slug: row[":id"],
                         meta: { "type" => row.cleaned_text("activitat") },
                         state: GobiertoCalendars::Event.states[:published],
                         interest_group_id: interest_group.id,
                         notify: false }
          event_form = GobiertoCalendars::EventForm.new(attributes)
          if event_form.persisted?
            puts "The event already exists. Checking for updates..."
            persisted_event_attributes = GobiertoCalendars::Event.find_by_external_id(row[":id"]).attributes.with_indifferent_access
            attributes.select! { |attribute, value| persisted_event_attributes.has_key?(attribute) && value != persisted_event_attributes[attribute] }
            if attributes.any?
              puts "Updates:"
              attributes.each do |attribute, value|
                puts "#{ attribute }: From #{ persisted_event_attributes[attribute] } to #{ value }"
              end
            else
              puts "No updates found"
            end
            event_form.save
          else
            save_new(event_form, attendees: [person])
          end
        else
          puts "Some associated resources couldn't be resolved, preventing the creation of event with external_id: #{ row[":id"] }"
          error = { resource_attrs: row.pretty_inspect,
                    resource_updated_at: row.datetime(":updated_at"),
                    not_persisted_resources: not_persisted_resources.map(&:pretty_inspect) }
          @errors << error
        end
        puts "===================================="
      rescue StandardError => e
        Rollbar.error(e, "Error processing row with external_id: #{ row[":id"] }")
      end

      super
    end

    def save_new(event_form, opts={})
      if (result = event_form.save)
        puts "Created event: #{ event_form.event.pretty_inspect }"
      else
        puts "Something failed trying to load event: #{ event_form.event.pretty_inspect }"
        puts "Errors summary: #{ event_form.errors.full_messages.pretty_inspect }"
      end
      result
    end
  end
end
