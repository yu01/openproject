#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemaRepresenter < ::API::Decorators::Single
          def self.property_schema(property,
                                   type: nil,
                                   title: nil,
                                   required: true,
                                   writable: true,
                                   min_length: nil,
                                   max_length: nil)
            raise ArgumentError if property.nil? || type.nil?

            title = I18n.t("activerecord.attributes.work_package.#{property}") unless title

            schema = ::API::Decorators::PropertySchemaRepresenter.new(type: type,
                                                                      name: title)
            schema.required = required
            schema.writable = writable
            schema.min_length = min_length if min_length
            schema.max_length = max_length if max_length

            property property,
                     getter: -> (*) { schema },
                     writeable: false
          end

          property_schema :_type,
                          type: 'MetaType',
                          title: I18n.t('api_v3.attributes._type'),
                          writable: false
          property_schema :lock_version,
                          type: 'Integer',
                          title: I18n.t('api_v3.attributes.lock_version'),
                          writable: false
          property_schema :id, type: 'Integer', writable: false
          property_schema :subject, type: 'String', min_length: 1, max_length: 255
          property_schema :description, type: 'Formattable'
          property_schema :start_date, type: 'Date', required: false
          property_schema :due_date, type: 'Date', required: false
          property_schema :estimated_time, type: 'Duration', required: false, writable: false
          property_schema :spent_time, type: 'Duration', writable: false
          property_schema :percentage_done,
                          type: 'Integer',
                          title: I18n.t('activerecord.attributes.work_package.done_ratio'),
                          writable: false
          property_schema :created_at, type: 'DateTime', writable: false
          property_schema :updated_at, type: 'DateTime', writable: false

          # non-writable links
          property_schema :author, type: 'User', writable: false
          property_schema :project, type: 'Project', writable: false
          property_schema :type, type: 'Type', writable: false

          property :assignee,
                   exec_context: :decorator,
                   getter: -> (*) {
                     link = api_v3_paths.available_assignees(represented.project.id)
                     representer = ::API::Decorators::AllowedValuesByLinkRepresenter.new(
                       type: 'User',
                       name: I18n.t('activerecord.attributes.work_package.assigned_to'))
                     representer.required = false

                     if represented.defines_assignable_values?
                       representer.allowed_values_href = link
                     end

                     representer
                   }

          property :responsible,
                   exec_context: :decorator,
                   getter: -> (*) {
                     link = api_v3_paths.available_responsibles(represented.project.id)
                     representer = ::API::Decorators::AllowedValuesByLinkRepresenter.new(
                       type: 'User',
                       name: I18n.t('activerecord.attributes.work_package.responsible'))
                     representer.required = false

                     if represented.defines_assignable_values?
                       representer.allowed_values_href = link
                     end

                     representer
                   }

          property :status,
                   exec_context: :decorator,
                   getter: -> (*) {
                     assignable_statuses = represented.assignable_statuses_for(current_user)
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Status',
                       name: I18n.t('activerecord.attributes.work_package.status'),
                       current_user: current_user,
                       value_representer: API::V3::Statuses::StatusRepresenter,
                       link_factory: -> (status) do
                                       {
                                         href: api_v3_paths.status(status.id),
                                         title: status.name
                                       }
                                     end)

                     representer.allowed_values = assignable_statuses
                     representer
                   }

          property :version,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Version',
                       name: I18n.t('activerecord.attributes.work_package.fixed_version'),
                       current_user: current_user,
                       value_representer: API::V3::Versions::VersionRepresenter,
                       link_factory: -> (version) do
                                       {
                                         href: api_v3_paths.version(version.id),
                                         title: version.name
                                       }
                                     end)

                     representer.required = false
                     representer.allowed_values = represented.assignable_versions
                     representer
                   }

          property :priority,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Priority',
                       name: I18n.t('activerecord.attributes.work_package.priority'),
                       current_user: current_user,
                       value_representer: API::V3::Priorities::PriorityRepresenter,
                       link_factory: -> (priority) do
                                       {
                                         href: api_v3_paths.priority(priority.id),
                                         title: priority.name
                                       }
                                     end)

                     representer.allowed_values = represented.assignable_priorities
                     representer
                   }

          def current_user
            context[:current_user]
          end

          def _type
            'MetaType'
          end
        end
      end
    end
  end
end