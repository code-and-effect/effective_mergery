module Admin
  class MergeController < ApplicationController
    before_action :authenticate_user! if defined?(Devise)

    layout (EffectiveMergery.layout.kind_of?(Hash) ? EffectiveMergery.layout[:admin_merge] : EffectiveMergery.layout)

    def index
      @page_title = 'Merges'
      EffectiveMergery.authorized?(self, :admin, :effective_mergery)
    end

    def new
      @page_title = 'New Merge'
      EffectiveMergery.authorized?(self, :admin, :effective_mergery)

      begin
        @merge = Effective::Merge.new(type: params[:type])
        @merge.validate_klass!
      rescue => e
        flash[:danger] = "An error occurred while loading #{@merge}: #{e.message}"
        redirect_to effective_mergery.admin_merge_index_path
      end
    end

    def create
      EffectiveMergery.authorized?(self, :admin, :effective_mergery)

      @merge = Effective::Merge.new(merge_params)

      if @merge.save
        @page_title = 'Successful Merge'
        flash[:success] = "Successfully merged #{@merge}"

        if defined?(EffectiveLogging)
          EffectiveLogger.success "Merged #{@merge}", user: (current_user rescue false), associated: @merge.target, source_id: @merge.source_id, target_id: @merge.target_id, mergable_type: @merge.type
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
      EffectiveMergery.authorized?(self, :admin, :effective_mergery)

      object = Effective::Merge.new(type: params[:type]).collection.find(params[:id])

      if object.present?
        render partial: '/admin/merge/attributes', locals: { resource: object }
      else
        render body: '<p>None Available</p>'
      end
    end

    private

    def merge_params
      params.require(:effective_merge).permit(:type, :source_id, :target_id)
    end

  end
end
