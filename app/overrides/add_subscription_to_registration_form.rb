Deface::Override.new(
  virtual_path: "spree/shared/_user_form",
  insert_before: "[data-hook='signup_below_password_fields']",
  partial: "spree/klaviyo/subscribe_field",
  name: "add_subscription_to_registration_form",
  original: ""
)
