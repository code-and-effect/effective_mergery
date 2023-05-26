module Admin
  class MergeController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_mergery) }

    include Effective::CrudController

    if (config = EffectiveMergery.layout)
      layout(config.kind_of?(Hash) ? config[:admin] : config)
    end

    def index
      @page_title = 'Merges'
    end

    def new
      @page_title = 'New Merge'

      begin
        @merge = Effective::Merge.new(type: params[:type])
        @merge.validate_klass!
      rescue => e
        flash[:danger] = "An error occurred while loading #{@merge}: #{e.message}"
        redirect_to effective_mergery.admin_merge_index_path
      end
    end

    def create
      @merge = Effective::Merge.new(merge_params)

      if @merge.save
        @page_title = 'Successful Merge'
        flash[:success] = "Successfully merged #{@merge}"

        if defined?(EffectiveLogging)
          EffectiveLogger.success(
            "Merged #{@merge} - #{@merge.source.respond_to?(:to_s_verbose) ? @merge.source.to_s_verbose : @merge.source.to_s}",
            user: (current_user rescue false),
            associated: @merge.target,
            source_id: @merge.source_id,
            target_id: @merge.target_id,
            mergable_type: @merge.type,
            source_email: (@merge.source.email if @merge.source.respond_to?(:email)),
            source_name: (@merge.source.full_name if @merge.source.respond_to?(:full_name))
          )
        end

        @merge.target = @merge.collection.find(@merge.target_id)
      else
        @page_title = 'New Merge'
        flash.now[:danger] = "Unable to merge #{@merge}: #{@merge.errors.full_messages.to_sentence}"

        render :new
      end
    end

    # This is the AJAX request for the object's attributes
    def attributes
      object = Effective::Merge.new(type: params[:type]).collection.find(params[:id])

      if object.present?
        render partial: '/admin/merge/attributes', locals: { resource: object }
      else
        render body: '<p>None Available</p>'
      end
    end

    private

    def merge_params
      params.require(:effective_merge).permit!
    end

  end
end
