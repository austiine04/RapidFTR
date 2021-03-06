class EnquiriesController < ApplicationController
  before_action :check_enquiry_feature_status
  before_action :load_enquiry, :only => [:show, :edit, :update]

  def index
    authorize! :index, Enquiry

    @page_name = t('home.view_records')
    @filter = params[:filter] || nil
    per_page = params[:per_page] || EnquiriesHelper::View::PER_PAGE
    per_page = per_page.to_i unless per_page == 'all'
    page = params[:page] || 1

    search = Search.for(Enquiry).
        paginated(page, per_page).
        marked_as(@filter)

    @enquiries = search.results

    flash[:notice] = t('enquiry.no_records_available') if @enquiries.empty?
  end

  def new
    @enquiry = Enquiry.new
    @form_sections = enquiry_form_sections
  end

  def create
    authorize! :create, Enquiry
    @enquiry = Enquiry.new_with_user_name current_user, params[:enquiry]

    if @enquiry.save
      flash[:notice] = t('enquiry.messages.creation_success')
      redirect_to(@enquiry)
    else
      @form_sections = enquiry_form_sections
      render :new
    end
  end

  def edit
    authorize! :update, Enquiry
    @form_sections = enquiry_form_sections
  end

  def update
    authorize! :update, Enquiry

    if @enquiry.update_attributes(params[:enquiry])
      flash[:notice] = t('enquiry.messages.update_success')
      redirect_to enquiry_path(@enquiry)
    else
      @form_sections = enquiry_form_sections
      render :edit
    end
  end

  def show
    authorize! :read, Enquiry
    @enquiry = Enquiry.find params[:id]
    @form_sections = enquiry_form_sections
  end

  def matches
    @filter = params[:filter] || nil
    @order = params[:order_by] || EnquiriesHelper::ORDER_BY[@filter] || 'created_at'
    @sort_order = (params[:sort_order].nil? || params[:sort_order].empty?) ? :asc : params[:sort_order]
    per_page = params[:per_page] || EnquiriesHelper::View::PER_PAGE
    page = params[:page] || 1

    @enquiries = Enquiry.with_child_potential_matches(:per_page => per_page, :page => page)

    render :template => 'enquiries/index_with_potential_matches'
  end

  private

  def load_enquiry
    @enquiry = Enquiry.find params[:id]
  end

  def enquiry_form_sections
    FormSection.enabled_by_order_for_form(Enquiry::FORM_NAME)
  end

  def check_enquiry_feature_status
    enquiries_enabled = SystemVariable.find_by_name(SystemVariable::ENABLE_ENQUIRIES)
    unless enquiries_enabled.nil? || enquiries_enabled.to_bool_value
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => 404
      return false
    end
  end
end
