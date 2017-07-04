EffectiveMergery.setup do |config|
  # Authorization Method
  #
  # This method is called by all controller actions with the appropriate action and resource
  # If the method returns false, an Effective::AccessDenied Error will be raised (see README.md for complete info)
  #
  # Use via Proc (and with CanCan):
  # config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) }
  #
  # Use via custom method:
  # config.authorization_method = :my_authorization_method
  #
  # And then in your application_controller.rb:
  #
  # def my_authorization_method(action, resource)
  #   current_user.is?(:admin)
  # end
  #
  # Or disable the check completely:
  # config.authorization_method = false
  config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) } # CanCanCan

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

  # Allow merges for only the following ActiveRecord class names:
  # config.only = ['User']

  # Allow merges on all ActiveRecord classes, except the following:
  # config.except = []

end
