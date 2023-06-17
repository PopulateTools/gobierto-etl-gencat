require "json"
require "uri"
require "net/http"
require "openssl"
require "erb"

module Utils
  class OriginDataset
    DATASET_IDS = {
      "development" => {
        events: "pada-92wh",
        gifts: "amh6-6pgd",
        invitations: "pxgs-vhxp",
        trips: "dze7-9jyh",
        charges: "t93n-tvdf"
      },
      "staging" => {
        events: "pada-92wh",
        gifts: "amh6-6pgd",
        invitations: "2u63-j8pw",
        trips: "dze7-9jyh",
        charges: "t93n-tvdf"
      },
      "production" => {
        events: "4npk-u4e8",
        gifts: "t4qw-gx3q",
        invitations: "na9g-qaxb",
        trips: "4ngp-d7x6",
        charges: "t93n-tvdf"
      }
    }
    DATASET_URLS = {
      default: {
        "development" => "https://ctti.azure-westeurope-prod.socrata.com/resource",
        "staging" => "https://ctti.azure-westeurope-prod.socrata.com/resource",
        "production" => "https://analisi.transparenciacatalunya.cat/resource"
      },
      charges: {
        "development" => "https://analisi.transparenciacatalunya.cat/resource",
        "staging" => "https://analisi.transparenciacatalunya.cat/resource",
        "production" => "https://analisi.transparenciacatalunya.cat/resource"
      }
    }
    DATASET_BASIC_AUTH = {
      charges: true
    }

    def self.valid_datasets(environment)
      DATASET_IDS[environment].keys
    end

    def initialize(opts={})
      @start_date = opts[:start_date]
      @end_date = opts[:end_date]
      @dataset = opts[:dataset]
      @basic_auth_credentials = opts[:basic_auth_credentials]
      @environment = opts[:environment].to_s
      @dataset_id = DATASET_IDS[@environment][opts[:dataset]]
      @url = DATASET_URLS.dig(@dataset, @environment) || DATASET_URLS.dig(:default, @environment)
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
      elsif @dataset == :trips
        "$order=Id ASC"
      elsif @dataset == :charges
        nil
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
      ERB::Util.url_encode("#{ @url }/#{ @dataset_id }.#{ format }?#{ conditions.compact.join("&") }")
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
      request.basic_auth(*@basic_auth_credentials.split(":")) if DATASET_BASIC_AUTH[@dataset]
      response = http.request(request)
      response.body
    end

    def auth_params
      return unless DATASET_BASIC_AUTH[@dataset]

      "--basic_auth #{@basic_auth_credentials}"
    end
  end
end
