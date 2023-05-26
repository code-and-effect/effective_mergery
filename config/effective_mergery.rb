EffectiveMergery.setup do |config|

 # Admin Screens Layout Settings
  config.layout = 'application'   # All EffectiveMergery controllers will use this layout

  # config.layout = {
  #   merge: 'application',
  #   admin_merge: 'admin',
  # }

  config.admin_simple_form_options = {}  # For the /admin/merge/new form
  # config.admin_simple_form_options = {
  #   :html => {:class => ['form-horizontal']},
  #   :wrapper => :horizontal_form,
  #   :wrapper_mappings => {
  #     :boolean => :horizontal_boolean,
  #     :check_boxes => :horizontal_radio_and_checkboxes,
  #     :radio_buttons => :horizontal_radio_and_checkboxes
  #   }
  # }

  # The class names that can be merged
  # config.class_names = ['User']
end
