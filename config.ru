require "fog/google"

module CustomPatch
  def initialize(options = {})
    shared_initialize(options[:google_project], Fog::Storage::GoogleJSON::GOOGLE_STORAGE_JSON_API_VERSION, Fog::Storage::GoogleJSON::GOOGLE_STORAGE_JSON_BASE_URL)
    options[:google_api_scope_url] = Fog::Storage::GoogleJSON::GOOGLE_STORAGE_JSON_API_SCOPE_URLS.join(" ")
    @host = options[:host] || "storage.googleapis.com"

    @client = initialize_google_client(options)

    # IAM client used for SignBlob API
    @iam_service = ::Google::Apis::IamcredentialsV1::IAMCredentialsService.new
    apply_client_options(@iam_service, {
                           google_api_scope_url: Fog::Storage::GoogleJSON::GOOGLE_STORAGE_JSON_IAM_API_SCOPE_URLS.join(" ")
                         })

    # Use Application Default Credential
    scopes = ["https://www.googleapis.com/auth/iam"]
    @iam_service.authorization = Google::Auth.get_application_default(scopes)

    @storage_json = ::Google::Apis::StorageV1::StorageService.new
    apply_client_options(@storage_json, options)
    @storage_json.client_options.open_timeout_sec = options[:open_timeout_sec] if options[:open_timeout_sec]
    @storage_json.client_options.read_timeout_sec = options[:read_timeout_sec] if options[:read_timeout_sec]
    @storage_json.client_options.send_timeout_sec = options[:send_timeout_sec] if options[:send_timeout_sec]
  end

  def iam_signer(string_to_sign)
    request = ::Google::Apis::IamcredentialsV1::SignBlobRequest.new(
      payload: string_to_sign
    )

    resource = "projects/-/serviceAccounts/#{google_access_id}"
    response = @iam_service.sign_service_account_blob(resource, request)

    return response.signed_blob
  end
end

Fog::Storage::GoogleJSON::Real.prepend(CustomPatch)

app = proc do |env|
  fog_storage = Fog::Storage::Google.new(google_project: ENV["GOOGLE_CLOUD_PROJECT"], google_application_default: true)
  signed_url = fog_storage.get_object_https_url(ENV["BUCKET_NAME"], ENV["OBJECT_NAME"], 600)

  [ 200, {"Content-Type" => "text/plain"}, [signed_url] ]
end

run app
