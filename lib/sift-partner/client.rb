require 'uri'
require 'json'
require 'httparty'
require 'sift' # we use Response

module SiftPartner

  # Ruby bindings for Sift Science's Partner API.
  # For background and examples on how to use the Partner API with this client
  # please refer to https://siftscience.com/resources/references/partner-ruby.html
  class Client
    API_ENDPOINT = "https://partner.siftscience.com/v3"
    API_TIMEOUT = 2

    #
    # Constructor
    # == Parameters:
    # api_key
    #   The api_key of the partner
    #   (which may be found in the api_keys section of the console)
    # id
    #   The account id of the partner
    #   (which may be found in the settings page of the console)
    def initialize(api_key = Sift.api_key, id = Sift.account_id)
      raise("api_key must be a non-empty string") unless valid_string?(api_key)
      raise("partner must be a non-empty string") unless valid_string?(id)
      @api_key = api_key
      @id = id
    end

    # Creates a new merchant account under the given partner.
    # == Parameters:
    # site_url
    #    the url of the merchant site
    # site_email
    #    an email address for the merchant
    # analyst_email
    #    an email address which will be used to log in at the Sift Console
    # password
    #    password (at least 10 chars) to be used to sign into the Console
    #
    # When successful, returns a including the new account id and credentials.
    # When an error occurs, returns nil.
    def new_account(site_url, site_email, analyst_email, password)

      raise("site url must be a non-empty string") unless valid_string?(site_url)
      raise("site email must be a non-empty string") unless valid_string?(site_email)
      raise("analyst email must be a non-empty string") unless valid_string?(analyst_email)
      raise("password must be a non-empty string") unless valid_string?(password)

      reqBody = {:site_url => site_url, :site_email => site_email,
                 :analyst_email => analyst_email, :password => password}
      begin
        http_post(accounts_url(), reqBody)
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end

    end

    # Gets a listing of the ids and keys for all merchant accounts that have
    # been created by this partner.
    #
    # When successful, returns a hash including the key :data, which is an
    # array of account descriptions. (Each element has the same structure as a
    # single response from new_account).
    def get_accounts()
      http_get(accounts_url)
    end

    # Updates the configuration which controls http notifications for all merchant
    # accounts under this partner.
    #
    # == Parameters
    # cfg
    #   A Hash, with keys :http_notification_url and :http_notification_threshold
    #   The value of the notification_url will be a url containing the string '%s' exactly once.
    #   This allows the url to be used as a template, into which a merchant account id can be substituted.
    #   The  notification threshold should be a floating point number between 0.0 and 1.0
    def update_notification_config(cfg = nil)

      raise("configuration must be a hash") unless cfg.is_a? Hash

      http_put(notification_config_url(), cfg)
    end

    private
      def accounts_url
        URI("#{API_ENDPOINT}/partners/#{@id}/accounts")
      end

      def user_agent
        "SiftScience/v#{API_VERSION} sift-partner-ruby/#{VERSION}"
      end

      def notification_config_url
        URI("#{API_ENDPOINT}/accounts/#{@id}/config")
      end

      def safe_json(http_response)
        response = Sift::Response.new(http_response.body, http_response.code)
        if !response.nil? and response.ok?
          response.json
        else
          puts "bad value in safeJson :"
          PP.pp(response)
        end
      end

      def prep_https(uri)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https
      end

      def http_get(uri)
        header =  {"Authorization" => "Basic #{@api_key}",
                    "User-Agent" => user_agent}

        http_response = HTTParty.get(uri, :headers =>header)
        safe_json(http_response)
      end

      def http_put(uri, bodyObj)
        header = {"Content-Type" => "application/json",
                  "Authorization" => "Basic #{@api_key}",
                  "User-Agent" => user_agent}

        http_response = HTTParty.put(uri, :body => bodyObj.to_json, :headers => header)
        safe_json(http_response)
      end

      def http_post(uri, bodyObj)
        header = {"Content-Type" => "application/json",
                  "Authorization" => "Basic #{@api_key}",
                  "User-Agent" => user_agent}
        http_response = HTTParty.post(uri, :body => bodyObj.to_json, :headers => header)
        safe_json(http_response)
      end

      def valid_string?(s)
        s.is_a?(String) && !s.empty?
      end
  end
end
