class ApiDoc

  def self.v1_block 
    block = %{
      short "Fingerbank API"
      description "All requests to the fingerbank API need to contain your API key in the URL parameters. You can find your key and regenerate it by accessing your account."
      param :key, String, :required => true, :desc => "Your API key", :meta => {'Type' => "URL"}
      error 401, "This request is unauthorized. Either your key is invalid or wasn't specified."
      error 403, "This request is forbidden. Your account may have been blocked."
    }
    return block
  end
end
