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
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
          if Rails::VERSION::MAJOR < 5
            alias_method_chain :initialize_available_filters, :more_filters
          else # Rails 5+
            alias_method :initialize_available_filters_without_more_filters, :initialize_available_filters
            alias_method :initialize_available_filters, :initialize_available_filters_with_more_filters
          end
          
          self.available_columns += [
            QueryColumn.new(:created_on_by_clock_time, 
              :sortable  => lambda { Redmine::Database.local_clock_time_sql(         Issue.table_name, "created_on", User.current.time_zone_or_default_identifier )}, 
              :groupable => lambda { Redmine::Database.hour_of_local_clock_time_sql( Issue.table_name, "created_on", User.current.time_zone_or_default_identifier )}
            ),
            QueryColumn.new(:updated_on_by_clock_time, 
              :sortable  => lambda { Redmine::Database.local_clock_time_sql(         Issue.table_name, "updated_on", User.current.time_zone_or_default_identifier )}, 
              :groupable => lambda { Redmine::Database.hour_of_local_clock_time_sql( Issue.table_name, "updated_on", User.current.time_zone_or_default_identifier )}
            )
          ]
          
        end #base
      end #self
      
      module InstanceMethods
      
        def initialize_available_filters_with_more_filters
        
          initialize_available_filters_without_more_filters
          
            add_available_filter("created_on_by_clock_time",
                :type => :time_past
            )
            add_available_filter("updated_on_by_clock_time",
                :type => :time_past
            )
          
            add_available_filter "and_any",
                :name => l(:label_orfilter_and_any),
                :type => :list,
                :values => [l(:general_text_Yes)],
                :group => 'or_filter'
            add_available_filter "or_any",
                :name => l(:label_orfilter_or_any),
                :type => :list,
                :values => [l(:general_text_Yes)],
                :group => 'or_filter'
            add_available_filter "or_all",
                :name => l(:label_orfilter_or_all),
                :type => :list,
                :values => [l(:general_text_Yes)],
                :group => 'or_filter'
        end #def
        
        def sql_for_created_on_by_clock_time_field(field, operator, value)
          sql_for_field( field, operator, value, Issue.table_name, 'created_on' )
        end #def
        
        def sql_for_updated_on_by_clock_time_field(field, operator, value)
          sql_for_field( field, operator, value, Issue.table_name, 'updated_on' )
        end #def
        
      end #module
    end #module
  end #module
end #module

unless IssueQuery.included_modules.include?(RedmineMoreFilters::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineMoreFilters::Patches::IssueQueryPatch)
end



