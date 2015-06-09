class DhcpFingerprint < CombinationAttribute
  scope :ignored, -> {where(:ignored => true)}
  scope :not_ignored, -> {where(:ignored => false)}
end
