class DhcpFingerprint < CombinationAttribute
  has_many :combinations

  scope :ignored, -> {where(:ignored => true)}
  scope :not_ignored, -> {where(:ignored => false)}
end
