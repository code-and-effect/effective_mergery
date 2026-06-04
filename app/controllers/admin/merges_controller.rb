module Admin
  class MergesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_mergery) }

    include Effective::CrudController

    page_title "Merge Users"

    def merge_params
      params.require(:effective_merge).permit!
    end

  end
end
