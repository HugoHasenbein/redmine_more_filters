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
    module QueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
          if Rails::VERSION::MAJOR < 5
            alias_method_chain :sql_for_field, :more_filters
            alias_method_chain :sql_for_custom_field, :more_filters
            alias_method_chain :statement, :more_filters
            
          else # Rails 5+
            alias_method :sql_for_field_without_more_filters, :sql_for_field
            alias_method :sql_for_field, :sql_for_field_with_more_filters
            
            alias_method :sql_for_custom_field_without_more_filters, :sql_for_custom_field
            alias_method :sql_for_custom_field, :sql_for_custom_field_with_more_filters
            
            alias_method :statement_without_more_filters, :statement
            alias_method :statement, :statement_with_more_filters
          end
          
          self.operators.merge!(
          
            "=="    => :label_is_strict,
            "!!"    => :label_is_not_strict,
            
            "^="    => :label_begins_with,
            "*^="   => :label_begins_with_any,
            "!^="   => :label_not_begins_with,
            "!*^="  => :label_not_begins_with_any,
            
            "$="    => :label_ends_with,
            "*$="   => :label_ends_with_any,
            "!$="   => :label_not_ends_with,
            "!*$="  => :label_not_ends_with_any,
            
            "*="    => :label_any_of,
            "!*="   => :label_none_of,
            
            "*~"    => :label_contains_any,
            "!*~"   => :label_not_contains_any,
            "[~]"   => :label_contains_all,
            "![~]"  => :label_not_contains_all,
            
            "nd"    => :label_tomorrow,
            "nw"    => :label_next_week,
            "nm"    => :label_next_month,
            "n3m"   => :label_next_three_months,
            
            "<<"    => :label_past,
            ">>"    => :label_future,
            
            ">h-"    => :label_less_than_hours_ago,
            "<h-"    => :label_more_than_hours_ago,
            "><h-"   => :label_between_ago,
            "><h"    => :label_between,
            
            "<<t"    => :label_past,
            "t>>"    => :label_future
            
          )
        
        self.operators_by_filter_type[:string].insert(1, "*=", "!*=", "^=", "*^=", "!^=", "!*^=", "$=", "*$=", "!$=", "!*$=", "*~", "!*~", "[~]", "![~]")
        self.operators_by_filter_type[:text].insert(  1,              "^=", "*^=", "!^=", "!*^=", "$=", "*$=", "!$=", "!*$=", "*~", "!*~", "[~]", "![~]")
        
        self.operators_by_filter_type[:date].insert(14, "n3m")
        self.operators_by_filter_type[:date].insert(15, "nm")
        self.operators_by_filter_type[:date].insert(11, "nw")
        self.operators_by_filter_type[:date].insert( 9, "nd")
        self.operators_by_filter_type[:date].insert( 9, ">>")
        self.operators_by_filter_type[:date].insert( 8, "<<")
        
        self.operators_by_filter_type[:date_past].insert( 8, "<<")
        
        self.operators_by_filter_type[:time_past] = [ ">h-", "<h-", "><h-", "<<t", "!*", "*", "><h" ]
        
        self.operators_by_filter_type[:list_multiple] = [ "=", "==", "[~]", "!", "!!", "![~]", "!*", "*" ]
          
        def validate_query_filters
          filters.each_key do |field|
            if values_for(field)
              case type_for(field)
              when :integer
                add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/\A[+-]?\d+(\D*?[+-]?\d+)*\z/) }
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
              when :time_past
                case operator_for(field)
                when ">h-", "<h-", "><h-", "><h-", "><h+"
                  add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^\d+$/) }
                when "><h"
                  add_filter_error(field, :invalid) if values_for(field).detect {|v| 
                    v.present? && (!v.match(/^\d{2}:\d{2}(:\d{2})?$/) || parse_time(v).nil?) 
                  }
                end
              end
            end
            add_filter_error(field, :blank) unless
                # filter requires one or more values
                (values_for(field) and !values_for(field).first.blank?) or
                # filter doesn't require any value
                ["o", "c", "!*", "*", "t", "ld", "nd", "<<", ">>", "<<t", "t>>", "w", "lw", "nw", "l2w", "m", "lm", "nm", "n3m", "y", "*o", "!o"].include? operator_for(field)
          end if filters
        end #def
        
        # Returns Time from the given filter value
        def parse_time(arg)
          Time.parse(arg) rescue nil
        end #def
        
        
        end #base
      end #self
      
      module InstanceMethods
        
        def sql_for_field_with_more_filters(field, operator, value, db_table, db_field, is_custom_filter=false)
          sql = case operator
            when "!*"
              s = "#{db_table}.#{db_field} IS NULL"
              s << " OR RTRIM(#{db_table}.#{db_field}) = ''" if (is_custom_filter || [:text, :string].include?(type_for(field)))
              s
            when "*"
              s = "#{db_table}.#{db_field} IS NOT NULL"
              s << " AND RTRIM(#{db_table}.#{db_field}) <> ''" if (is_custom_filter || [:text, :string].include?(type_for(field)))
              s
            when "^="
              sql_begins_with("#{db_table}.#{db_field}", value.first)
            when "*^="
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_begins_with("#{db_table}.#{db_field}", s)}.join(" OR ")
            when "!^="
              sql_begins_with("#{db_table}.#{db_field}", value.first, false)
            when "!*^="
              value.first.split(" ").select{|s| s.present?}.map{|s| sql_begins_with("#{db_table}.#{db_field}", s, false)}.join(" AND ")
              
            when "*="
              sql_one_of("#{db_table}.#{db_field}", value.first.split(" ").select{|s| s.present?}, true)
              
            when "!*="
              sql_one_of("#{db_table}.#{db_field}", value.first.split(" ").select{|s| s.present?}, false)
              
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
              
            when "<<t"
              relative_time_clause(db_table, db_field, nil, nil, 0, nil)
            when "t>>"
              relative_time_clause(db_table, db_field, 0, nil, nil, nil)
              
            when ">h-"
              relative_time_clause(db_table, db_field, value.first.to_i * (-1), "hour", nil, nil)
            when "<h-"
              relative_time_clause(db_table, db_field, nil, nil, value.first.to_i * (-1), "hour")
            when "><h-"
              relative_time_clause(db_table, db_field, - value[1].to_i, "hour", - value[0].to_i, "hour")
            when "><h+"
              relative_time_clause(db_table, db_field, value[1].to_i, "hour", value[0].to_i, "hour")
            when "><h"
              local_clock_time_clause(db_table, db_field, value[0], value[1], get_timezone )
              
            when "<<"
              relative_date_clause(db_table, db_field, nil, -1, is_custom_filter)
            when ">>"
              relative_date_clause(db_table, db_field, 0, nil, is_custom_filter)
              
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
            when "n3m"
             # = next three months
             date = User.current.today.advance(:months => 3)
             date_clause(db_table, db_field, User.current.today, date, is_custom_filter)
            when "="
              sql_for_field_without_more_filters(field, operator, value, db_table, db_field, is_custom_filter)
            else
              sql_for_field_without_more_filters(field, operator, value, db_table, db_field, is_custom_filter)
          end
          return sql
        end #def
        
        def sql_for_custom_field_with_more_filters(field, operator, value, custom_field_id)
          db_table = CustomValue.table_name
          db_field = 'value'
          #filter = @available_filters[field]
          filter = available_filters[field]
          return nil unless filter
          if filter[:field].format.target_class && filter[:field].format.target_class <= User
            if value.delete('me')
              value.push User.current.id.to_s
            end
          end
          not_in = nil
          if operator == '!'
            # Makes ! operator work for custom fields with multiple values
            operator = '='
            not_in = 'NOT'
          end
          if operator == "!!"
            operator = "!"
          end
          customized_key = "id"
          customized_class = queried_class
          if field =~ /^(.+)\.cf_/
            assoc = $1
            customized_key = "#{assoc}_id"
            customized_class = queried_class.reflect_on_association(assoc.to_sym).klass.base_class rescue nil
            raise "Unknown #{queried_class.name} association #{assoc}" unless customized_class
          end
          where = sql_for_field_with_more_filters(field, operator, value, db_table, db_field, true)
          if operator =~ /[<>]/
            where = "(#{where}) AND #{db_table}.#{db_field} <> ''"
          end
           "#{queried_table_name}.#{customized_key} #{not_in} IN (" +
            "SELECT #{customized_class.table_name}.id FROM #{customized_class.table_name}" +
            " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='#{customized_class}' AND #{db_table}.customized_id=#{customized_class.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id}" +
            " WHERE (#{where}) AND (#{filter[:field].visibility_by_project_condition}))"
        end

        def statement_with_more_filters
          # filters clauses
          filters_clauses = []
          filters.each_key do |field|
            next if field == "subproject_id"
            v = values_for(field).clone
            next unless v and !v.empty?
            operator = operator_for(field)
      
            # "me" value substitution
            if %w(assigned_to_id author_id user_id watcher_id updated_by last_updated_by attachment_author_id).include?(field)
              if v.delete("me")
                if User.current.logged?
                  v.push(User.current.id.to_s)
                  v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
                else
                  v.push("0")
                end
              end
            end
      
            if field == 'project_id'
              if v.delete('mine')
                v += User.current.memberships.map(&:project_id).map(&:to_s)
              end
            end
      
            if field =~ /^cf_(\d+)\.cf_(\d+)$/
              filters_clauses << sql_for_chained_custom_field(field, operator, v, $1, $2)
            elsif field =~ /cf_(\d+)$/
              # custom field
              if v.is_a?(Array)
                case operator
                when "=="
                  fc = []
                  v.each do |sv|
                    fc << sql_for_custom_field_with_more_filters(field, "=", [sv], $1)
                  end
                  filters_clauses << fc.join(' AND ')
                  filters_clauses << (" NOT " + sql_for_custom_field_with_more_filters(field, "!!", v, $1))
                when "[~]"
                  fc = []
                  v.each do |sv|
                    fc << sql_for_custom_field_with_more_filters(field, "=", [sv], $1)
                  end
                  filters_clauses << fc.join(' AND ')
                when "![~]"
                  fc = []
                  v.each do |sv|
                    fc << sql_for_custom_field_with_more_filters(field, "=", [sv], $1)
                  end
                  filters_clauses << (" NOT (" + fc.join(' AND ') + ")")
                when "!!"
                  fc = []
                  v.each do |sv|
                    fc << sql_for_custom_field_with_more_filters(field, "=", [sv], $1)
                  end
                  filters_clauses << (" NOT (" + fc.join(' AND ') + " AND NOT " + sql_for_custom_field_with_more_filters(field, "!!", v, $1) + ")")
                else
                  filters_clauses << sql_for_custom_field_with_more_filters(field, operator, v, $1)
                end
              else
                filters_clauses << sql_for_custom_field_with_more_filters(field, operator, v, $1)
              end
            elsif field =~ /^cf_(\d+)\.(.+)$/
              filters_clauses << sql_for_custom_field_attribute(field, operator, v, $1, $2)
            elsif respond_to?(method = "sql_for_#{field.gsub('.','_')}_field")
              # specific statement
              filters_clauses << send(method, field, operator, v)
            else
              # regular field
              filters_clauses << ('(' + sql_for_field_with_more_filters(field, operator, v, queried_table_name, field) + ')')
            end
          end if filters and valid?
      
          if (c = group_by_column) && c.is_a?(QueryCustomFieldColumn)
            # Excludes results for which the grouped custom field is not visible
            filters_clauses << c.custom_field.visibility_by_project_condition
          end

          filters_clauses << project_statement
          filters_clauses.reject!(&:blank?)
        
          filters_clauses.any? ? filters_clauses.join(' AND ') : nil
        end
        
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
        
        # Returns a SQL IN statement 
        def sql_one_of(db_field, values, match=true)
          queried_class.send :sanitize_sql_for_conditions,
            "#{db_field} #{match ? '' : 'NOT'} IN (#{values.map{|v| "'#{ActiveRecord::Base.connection.quote_string(v)}'"}.join(', ')})" 
        end #def
        
        # Returns a SQL clause for a time field.
        def relative_time_clause(table, field, from, from_epoch, to, to_epoch )
          s            = []
          from_epoch ||= "second"
          to_epoch   ||= "second"
          if from
            s << ("#{table}.#{field} > %s" % [Redmine::Database.relative_time( from, from_epoch )])
          end
          if to
            s << ("#{table}.#{field} <= %s" % [Redmine::Database.relative_time( to, to_epoch )])
          end
          s.join(' AND ')
        end #def
        
        # Returns a SQL clause for a time field in local time
        # interprets the string as User local time
        # User local time is converted to utc, which is database time
        #
        def local_clock_time_clause(table, field, from, to, time_zone )
          s = []
          
          if from
            s << ("(#{Redmine::Database.local_clock_time_sql(table, field, time_zone)}) > '%s'" % [from])
          end
          if to
            s << ("(#{Redmine::Database.local_clock_time_sql(table, field, time_zone)}) <= '%s'" % [to])
          end
          s.join(' AND ')
        end #def
        
        def get_timezone
          return User.current.time_zone_or_default_identifier if User.current
          return ActiveSupport::TimeZone[RedmineApp::Application.config.time_zone] if RedmineApp::Application.config.time_zone
          "Etc/UTC"
        end #def
        
      end
    end
  end
end

unless Query.included_modules.include?(RedmineMoreFilters::Patches::QueryPatch)
  Query.send(:include, RedmineMoreFilters::Patches::QueryPatch)
end



