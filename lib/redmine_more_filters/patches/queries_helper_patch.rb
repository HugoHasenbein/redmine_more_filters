# encoding: utf-8
#
# Redmine plugin to add necessary filters to queries
#
# Copyright © 2019-2020 Stephan Wenzel <stephan.wenzel@drwpatent.de>
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

module RedmineMoreFilters
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
            if Rails::VERSION::MAJOR < 5
              alias_method_chain :filters_options_for_select, :more_filters
              alias_method_chain :column_value, :more_filters
              
            else
              alias_method :filters_options_for_select_without_more_filters, :filters_options_for_select
              alias_method :filters_options_for_select, :filters_options_for_select_with_more_filters
              
              alias_method :column_value_without_more_filters, :column_value
              alias_method :column_value, :column_value_with_more_filters
            end
            
        end #base 
      end #self
      
      module InstanceMethods
      
        def column_value_with_more_filters(column, item, value)
          case column.name
          when :created_on_by_clock_time
            item.created_on.in_time_zone(User.current.time_zone_or_default_identifier).strftime("%H:%M:%S")
          when :updated_on_by_clock_time
            item.updated_on.in_time_zone(User.current.time_zone_or_default_identifier).strftime("%H:%M:%S")
          else
            column_value_without_more_filters(column, item, value)
          end
        end #def
        
        def filters_options_for_select_with_more_filters(query)
          ungrouped = []
          grouped = {}
          query.available_filters.map do |field, field_options|
            if field_options[:type] == :relation
              group = :label_relations
            elsif field_options[:type] == :tree
              group = query.is_a?(IssueQuery) ? :label_relations : nil
            elsif field =~ /root_id|all_relations/ 
              group = :label_relations
            elsif field =~ /^cf_\d+\./
              group = (field_options[:through] || field_options[:field]).try(:name)
            elsif field =~ /^(.+)\./
              # association filters
              group = "field_#{$1}".to_sym
            elsif %w(member_of_group assigned_to_role).include?(field)
              group = :field_assigned_to
            elsif field_options[:type] == :time_past
              group = :label_time
            elsif field_options[:type] == :date_past || field_options[:type] == :date
              group = :label_date
            elsif %w(attachment_filename attachment_description attachment_created attachment_created_on_by_clock_time attachment_author_id).include?(field)
              group = :label_issue_attachment
            elsif %w(notes).include?(field)
              group = :label_notes
            end
            if group
              (grouped[group] ||= []) << [field_options[:name], field]
            else
              ungrouped << [field_options[:name], field]
            end
          end
          # don't group dates if there's only one (eg. time entries filters)
          if grouped[:label_date].try(:size) == 1
            ungrouped << grouped.delete(:label_date).first
          end
          if grouped[:label_time].try(:size) == 1
            ungrouped << grouped.delete(:label_time).first
          end
          s = options_for_select([[]] + ungrouped)
          if grouped.present?
            localized_grouped = grouped.map {|k,v| [k.is_a?(Symbol) ? l(k) : k.to_s, v]}
            s << grouped_options_for_select(localized_grouped)
          end
          s
        end #def
        
      end #module
    end #module
  end #module
end #module

unless QueriesHelper.included_modules.include?(RedmineMoreFilters::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineMoreFilters::Patches::QueriesHelperPatch)
end



