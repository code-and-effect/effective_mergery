EffectiveMergery.setup do |config|
  # config.layout = {
  #   merge: 'application',
  #   admin_merge: 'admin',
  # }

  # Per-model hooks (define these class methods on a mergeable model):
  #
  #   def self.effective_mergery_collection           # records available to merge
  #   def self.effective_mergery_form_collection      # dropdown options (defaults to the collection)
  #   def self.effective_mergery_excluded_associations # associations kept on the source, e.g. [:addresses]
end
