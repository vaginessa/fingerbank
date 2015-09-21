module DhcpFingerprintsHelper
  def dhcp_fingerprint_search(fingerprint,scope = nil)
    uri = scope == "unknown" ? "/combinations/unknown" : "/combinations"
    "#{uri}?search=%5E#{URI.escape fingerprint}%24&fields%5B%5D=dhcp_fingerprints.value"
  end
end
