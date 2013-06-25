#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class CustomFieldsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :blank_translation_attributes_as_nil, :only => [:new, :edit]

  def index
    @custom_fields_by_type = CustomField.find(:all).group_by {|f| f.class.name }
    @tab = params[:tab] || 'WorkPackageCustomField'
  end

  def new
    @custom_field = begin
      if params[:type].to_s.match(/.+CustomField$/)
        params[:type].to_s.constantize.new(params[:custom_field])
      end
    rescue
    end
    (redirect_to(:action => 'index'); return) unless @custom_field.is_a?(CustomField)

    if request.post? and @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    else
      @trackers = Tracker.find(:all, :order => 'position')
    end
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if request.put? and @custom_field.update_attributes(params[:custom_field])
      flash[:notice] = l(:notice_successful_update)
      call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    else
      @trackers = Tracker.find(:all, :order => 'position')
    end
  end

  def destroy
    @custom_field = CustomField.find(params[:id]).destroy
    redirect_to :action => 'index', :tab => @custom_field.class.name
  rescue
    flash[:error] = l(:error_can_not_delete_custom_field)
    redirect_to :action => 'index'
  end

  private

  def blank_translation_attributes_as_nil
    return unless params['custom_field'] && params['custom_field']['translations_attributes']

    params['custom_field']['translations_attributes'].each do |index, attributes|
      attributes.each do |key, value|
        attributes[key] = nil if value.blank?
      end
    end
  end
end
