class Admin::SupportingDocumentsController < Admin::BaseController
  before_filter :find_document, only: [:new, :create]
  before_filter :find_supporting_page, only: [:show, :edit, :update, :destroy]

  def new
    @supporting_page = @document.supporting_pages.build(params[:supporting_document])
  end

  def create
    @supporting_page = @document.supporting_pages.build(params[:supporting_document])
    if @supporting_page.save
      redirect_to admin_document_path(@document), notice: "The supporting page was added successfully"
    else
      flash[:alert] = "There was a problem: #{@supporting_page.errors.full_messages.to_sentence}"
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @supporting_page.update_attributes(params[:supporting_document])
      redirect_to admin_supporting_document_path(@supporting_page), notice: "The supporting page was updated successfully"
    else
      flash[:alert] = "There was a problem: #{@supporting_page.errors.full_messages.to_sentence}"
      render :edit
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:alert] = %{This document has been saved since you opened it. Your version appears at the top and the latest version appears at the bottom. Please incorporate any relevant changes into your version and then save it.}
    @conflicting_supporting_page = SupportingDocument.find(params[:id])
    @supporting_page.lock_version = @conflicting_supporting_page.lock_version
    render action: "edit"
  end

  def destroy
    if @supporting_page.destroyable?
      @supporting_page.destroy
      flash[:notice] = %{"#{@supporting_page.title}" destroyed.}
    else
      flash[:alert] = "Cannot destroy a supporting page that has been published"
    end
    redirect_to admin_document_path(@supporting_page.document)
  end

  private

  def find_document
    @document = Document.find(params[:document_id])
  end

  def find_supporting_page
    @supporting_page = SupportingDocument.find(params[:id])
  end
end