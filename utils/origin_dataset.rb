require "json"
require "uri"
require "net/http"
require "openssl"

module Utils
  class OriginDataset
    DATASET_IDS = { events: "4npk-u4e8",
                    gifts: "t4qw-gx3q",
                    invitations: "na9g-qaxb",
                    trips: "5kte-hque" }
    URL = "https://analisi.transparenciacatalunya.cat/resource"

    def self.valid_datasets
      DATASET_IDS.keys
    end

    def initialize(opts={})
      @start_date = opts[:start_date]
      @end_date = opts[:end_date]
      @dataset = opts[:dataset]
      @dataset_id = DATASET_IDS[opts[:dataset]]
    end

    def date_interval_condition
      return nil if @start_date.blank? && @end_date.blank?
      if @end_date.blank?
        "$where=:updated_at >= '#{ @start_date.utc.iso8601 }'"
      elsif @start_date.blank?
        "$where=:updated_at <= '#{ @end_date.utc.iso8601 }'"
      else
        "$where=:updated_at between '#{ @start_date.utc.iso8601 }' and '#{ @end_date.utc.iso8601 }'"
      end
    end

    def sort_condition
      if [:events, :gifts].include?(@dataset)
        "$order=data ASC"
      elsif @dataset == :invitations
        "$order=data_inici ASC"
      else
        raise StandardError, "Unknown sort condition for this dataset"
      end
    end

    def select_condition
      "$select=:*,*"
    end

    def limit_condition(amount)
      "$limit=#{ amount }"
    end

    def query_url(conditions, format="csv")
      URI.encode("#{ URL }/#{ @dataset_id }.#{ format }?#{ conditions.compact.join("&") }")
    end

    def data_count
      @data_count ||= begin
                        resp = JSON.parse load_data(query_url([date_interval_condition, "$select=count(:id)"], "json"))
                        resp[0]["count_id"].to_i
                      end
    end

    def download_data_url
      query_url([date_interval_condition, sort_condition, limit_condition(data_count), select_condition])
    end

    def download
      content = load_data(query_url([date_interval_condition, sort_condition, limit_condition(data_count), select_condition]))
      file = Utils::LocalStorage.new(content: content, destination_path: File.join(DOWNLOAD_DESTINATION_PATH, "#{ @dataset }.csv"))
      file.upload!
      return 0
    end

    def load_data(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      response.body
    end
  end
end
