require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe SiftPartner::Client do
  partner_id = "65653548"
  partner_api_key = "98463454389754"
  site_url = "merchant123.com"
  site_email = "owner@merchant123.com"
  analyst_email = "analyst+merchant123@partner.com"
  password = "s0m3l0ngp455w0rd"

  expected_account_body = {
      "account_id" => "1234567890abcdef",
      "production" => {
        "api_keys" => [
          {
            "id" => "54321abcdef",
            "state" => "ACTIVE",
            "key" => "fedcba0987654321"
          }
        ],
        "beacon_keys" => [
          {
            "id" => "4321abcdef5",
            "state" => "ACTIVE",
            "key" => "edcba0987654321f"
          }
        ]
      },
      "sandbox" => {
        "api_keys" => [
          {
            "id" => "321abcdef54",
            "state" => "ACTIVE",
            "key" => "dcba0987654321fe"
          }
        ],
        "beacon_keys" => [
          {
            "id" => "21abcdef543",
            "state" => "ACTIVE",
            "key" => "cba0987654321fed"
          }
        ]
      }
    }

  it "Cannot instantiate client with nil, empty, or non-string api key" do
    lambda { Sift::Client.new(nil, partner_id) }.should raise_error
    lambda { Sift::Client.new("", partner_id) }.should raise_error
    lambda { Sift::Client.new(123456, partner_id) }.should raise_error
  end

  it "Cannot instantiate client with nil, empty, or non-string partner id" do
    lambda { Sift::Client.new(partner_api_key, nil) }.should raise_error
    lambda { Sift::Client.new(partner_api_key, "") }.should raise_error
    lambda { Sift::Client.new(partner_api_key, 123456) }.should raise_error
  end

  it "Can instantiate client with blank api key if Sift.api_key set" do
    lambda { Sift::Client.new(partner_api_key, partner_id) }.should_not raise_error
  end

  it "account creation fails with nil, empty, or non-string site url" do
    partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
    lambda { partner_client.new_account(nil, site_email, analyst_email,
      password) }.should raise_error
    lambda { partner_client.new_account("", site_email, analyst_email,
      password) }.should raise_error
    lambda { partner_client.new_account(12345, site_email, analyst_email,
      password) }.should raise_error
  end

  it "account creation fails with nil, empty, or non-string site email" do
    partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
    lambda { partner_client.new_account(site_url, nil, analyst_email,
      password) }.should raise_error
    lambda { partner_client.new_account(site_url, "", analyst_email,
      password) }.should raise_error
    lambda { partner_client.new_account(site_url, 12345, analyst_email,
      password) }.should raise_error
  end

  it "account creation fails with nil, empty, or non-string analyst email" do
    partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
    lambda { partner_client.new_account(site_url, site_email, nil,
      password) }.should raise_error
    lambda { partner_client.new_account(site_url, site_email, "",
      password) }.should raise_error
    lambda { partner_client.new_account(site_url, site_email, 12345,
      password) }.should raise_error
  end

  it "account creation fails with nil, empty, or non-string password" do
    partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
    lambda { partner_client.new_account(site_url, site_email, analyst_email,
     nil) }.should raise_error
    lambda { partner_client.new_account(site_url, site_email, analyst_email,
     "") }.should raise_error
    lambda { partner_client.new_account(site_url, site_email, analyst_email,
     12345) }.should raise_error
  end

  it "should march through create acct flow" do
    # when we receive the mocked url, it will include the basic auth header encoded
    # and regurgitated before the host name
    stub_request(:post, /https:\/\/.*\@partner\.siftscience\.com\/v3\/partners\/#{partner_id}\/accounts/).
      with { |request|
        parsed_body = JSON.parse(request.body)
        parsed_body.should include("site_url" => site_url)
        parsed_body.should include("site_email" => site_email)
        parsed_body.should include("analyst_email" => analyst_email)
        parsed_body.should include("password" => password)
      }.to_return({
        :status => 200,
        :headers => {},
        :body => expected_account_body.to_json})
      partner_client = SiftPartner::Client.new(partner_api_key, partner_id)

      response = partner_client.new_account(site_url, site_email, analyst_email,
      password)
      response.should_not be_nil
      response["production"]["api_keys"][0]["state"].should eq("ACTIVE")
    end

  it "should march through account listing flow" do
    stub_request(:get, /https:\/\/.*partner\.siftscience\.com\/v3\/partners\/#{partner_id}\/accounts/).
      to_return(
        {:body =>
          { "type" => "partner_account", "data" => [expected_account_body.to_json],
            "hasMore" => false,
            "nextRef" => nil,
            "totalResults" => 1}.to_json,
         :status => 200,
         :headers => {}}
      )
      partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
      response = partner_client.get_accounts()
      response.should_not be_nil
      response["totalResults"].should eq(1)
  end

  

  it "config update fails with nil, or non-hash notification threshold" do
    partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
    lambda { partner_client.update_notification_config(nil) }.should raise_error
    lambda { partner_client.update_notification_config("not_a_hash") }.should raise_error
  end

  it "should work through config update flow" do
    stub_request(:put, /https:\/\/.*\@partner\.siftscience\.com\/v3\/accounts\/#{partner_id}\/config/).
      with { |request|
        parsed_body = JSON.parse(request.body)
        parsed_body.should include("http_notification_threshold" => 0.1)
        parsed_body.should include("http_notification_url" => "https://api.partners.com/notify?account=%s")
      }.to_return({:status => 200, :headers => {},
          :body => {
            "email_notifiction_threshold" => 0.899,
            "http_notification_url" => "https://api.partners.com/notify?account=%s",
            "http_notification_threshold" => 0.1,
            "is_production" => true,
            "enable_sor_by_expected_loss" => false
          }.to_json
      })
      partner_client = SiftPartner::Client.new(partner_api_key, partner_id)
      cfg = {
        "http_notification_url" => "https://api.partners.com/notify?account=%s",
        "http_notification_threshold" => 0.1
      }
      response = partner_client.update_notification_config(cfg)
      response.should_not be_nil
      epsilon = 1e-6
      response["http_notification_url"].should eq(cfg["http_notification_url"])
      response["http_notification_threshold"].should < cfg["http_notification_threshold"] + epsilon
      response["http_notification_threshold"].should > cfg["http_notification_threshold"] - epsilon

  end

end
