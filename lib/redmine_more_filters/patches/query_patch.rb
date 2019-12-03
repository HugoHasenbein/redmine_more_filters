# encoding: utf-8
#
# Redmine plugin to add necessary filters to queries
#
# Copyright © 2019 Stephan Wenzel <stephan.wenzel@drwpatent.de>
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
    module QueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
          alias_method :sql_for_field_without_more_filters, :sql_for_field
          alias_method :sql_for_field, :sql_for_field_with_more_filters
          alias_method :more_filters, :sql_for_field
          
          self.operators.merge!(
            "^="    => :label_begins_with,
            "*^="   => :label_begins_with_any,
            "!^="   => :label_not_begins_with,
            "!*^="  => :label_not_begins_with_any,
            
            "$="    => :label_ends_with,
            "*$="   => :label_ends_with_any,
            "!$="   => :label_not_ends_with,
            "!*$="  => :label_not_ends_with_any,
            
            "*~"    => :label_contains_any,
            "!*~"   => :label_not_contains_any,
            "[~]"   => :label_contains_all,
            "![~]"  => :label_not_contains_all,
            
            "nd"    => :label_tomorrow,
            "nw"    => :label_next_week,
            "nm"    => :label_next_month
          )
          self.operators_by_filter_type[:string].insert(1, "^=", "*^=", "!^=", "!*^=", "$=", "*$=", "!$=", "!*$=", "*~", "!*~", "[~]", "![~]")
          self.operators_by_filter_type[:text].insert(1, "^=", "*^=", "!^=", "!*^=", "$=", "*$=", "!$=", "!*$=", "*~", "!*~", "[~]", "![~]")
          
          self.operators_by_filter_type[:date].insert(14, "nm")
          self.operators_by_filter_type[:date].insert(11, "nw")
          self.operators_by_filter_type[:date].insert(9, "nd")
          
        def validate_query_filters
          filters.each_key do |field|
            if values_for(field)
              case type_for(field)
              when :integer
                add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/\A[+-]?\d+(,[+-]?\d+)*\z/) }
              when :float
                add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/\A[+-]?\d+(\.\d*)?\z/) }
              when :date, :date_past
                case operator_for(field)
                when "=", ">=", "<=", "><"
                  add_filter_error(field, :invalid) if values_for(field).detect {|v|
                    v.present? && (!v.match(/\A\d{4}-\d{2}-\d{2}(T\d{2}((:)?\d{2}){0,2}(Z|\d{2}:?\d{2})?)?\z/) || parse_date(v).nil?)
                  }
                when ">t-", "<t-", "t-", ">t+", "<t+", "t+", "><t+", "><t-"
                  add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^\d+$/) }
                end
              end
            end
            add_filter_error(field, :blank) unless
                # filter requires one or more values
                (values_for(field) and !values_for(field).first.blank?) or
                # filter doesn't require any value
                ["o", "c", "!*", "*", "t", "ld", "nd", "w", "lw", "nw", "l2w", "m", "lm", "nm", "y", "*o", "!o"].include? operator_for(field)
          end if filters
        end
        
        end #base
      end #self
      
      module InstanceMethods
      
        
        def sql_for_field_with_more_filters(field, operator, value, db_table, db_field, is_custom_filter=false)
          sql = case operator
          
            when "^="
              sql_begins_with("#{db_table}.#{db_field}", value.first)
            when "*^="
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_begins_with("#{db_table}.#{db_field}", s)}.join(" OR ")
            when "!^="
              sql_begins_with("#{db_table}.#{db_field}", value.first, false)
            when "!*^="
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_begins_with("#{db_table}.#{db_field}", s, false)}.join(" AND ")
              
            when "$="
              sql = sql_ends_with("#{db_table}.#{db_field}", value.first)
            when "*$="
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_ends_with("#{db_table}.#{db_field}", s)}.join(" OR ")
            when "!$="
              sql_ends_with("#{db_table}.#{db_field}", value.first, false)
            when "!*$="
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_ends_with("#{db_table}.#{db_field}", s, false)}.join(" AND ")
              
            when "*~"
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_contains("#{db_table}.#{db_field}", s)}.join(" OR ")
            when "!*~"
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_contains("#{db_table}.#{db_field}", s, false)}.join(" AND ")
            when "[~]"
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_contains("#{db_table}.#{db_field}", s)}.join(" AND ")
            when "![~]"
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_contains("#{db_table}.#{db_field}", s, false)}.join(" OR ")
              
            when "nd"
              # = tomorrow
              relative_date_clause(db_table, db_field, 1, 1, is_custom_filter)
            when "nw"
              # = next week
              first_day_of_week = l(:general_first_day_of_week).to_i
              day_of_week = User.current.today.cwday
              days_since = 7 - day_of_week - first_day_of_week
              relative_date_clause(db_table, db_field, days_since, days_since + 7, is_custom_filter)
            when "nm"
             # = next month
             date = User.current.today.next_month
             date_clause(db_table, db_field, date.beginning_of_month, date.end_of_month, is_custom_filter)
            else
              sql_for_field_without_more_filters(field, operator, value, db_table, db_field, is_custom_filter)
          end
          return sql
        end #def
        
        # Returns a SQL LIKE statement with wildcards
        def sql_begins_with(db_field, value, match=true)
          queried_class.send :sanitize_sql_for_conditions,
            [Redmine::Database.like(db_field, '?', :match => match), "#{value}%"]
        end #def
        
        # Returns a SQL LIKE statement with wildcards
        def sql_ends_with(db_field, value, match=true)
          queried_class.send :sanitize_sql_for_conditions,
            [Redmine::Database.like(db_field, '?', :match => match), "%#{value}"]
        end #def
        
      end
    end
  end
end

unless Query.included_modules.include?(RedmineMoreFilters::Patches::QueryPatch)
  Query.send(:include, RedmineMoreFilters::Patches::QueryPatch)
end



