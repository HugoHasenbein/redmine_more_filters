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
            
            "<<"    => :label_past,
            ">>"    => :label_future,
            
            ">h-"    => :label_less_than_hours_ago,
            "<h-"    => :label_more_than_hours_ago,
            "><h-"   => :label_between_ago,
            "><h"    => :label_between,
            
            "<<t"    => :label_past,
            "t>>"    => :label_future,
            
            "match"  => :label_match,
            "!match" => :label_not_match
          )
        
        self.operators_by_filter_type[:string].insert(1, "*=", "!*=", "^=", "*^=", "!^=", "!*^=", "$=", "*$=", "!$=", "!*$=", "*~", "!*~", "[~]", "![~]")
        self.operators_by_filter_type[:text].insert(1, "^=", "*^=", "!^=", "!*^=", "$=", "*$=", "!$=", "!*$=", "*~", "!*~", "[~]", "![~]", "match", "!match" )
        
        self.operators_by_filter_type[:date].insert(14, "nm")
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
                ["o", "c", "!*", "*", "t", "ld", "nd", "<<", ">>", "<<t", "t>>", "w", "lw", "nw", "l2w", "m", "lm", "nm", "y", "*o", "!o"].include? operator_for(field)
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
            when "="
              sql_for_field_without_more_filters(field, operator, value, db_table, db_field, is_custom_filter)
            when "match"
              sql = sql_for_match_operators(field, operator, value, db_table, db_field, is_custom_filter)
            when "!match"
              sql = sql_for_match_operators(field, operator, value, db_table, db_field, is_custom_filter)              
            else
              sql_for_field_without_more_filters(field, operator, value, db_table, db_field, is_custom_filter)
          end
          return sql
        end #def
 
        def sql_for_match_operators(field, operator, value, db_table, db_field, is_custom_filter=false)
          sql = ''
          v = "(" + value.first.strip + ")"
     
          match = true
          op = ""
          term = ""
          in_term = false
     
          in_bracket = false
     
          v.chars.each do |c|
     
            if (!in_bracket && "()+~!".include?(c) && in_term  ) || (in_bracket && "}".include?(c))
              if !term.empty?
                sql += "(" + sql_contains("#{db_table}.#{db_field}", term, match) + ")"
              end
              #reset
              op = ""
              term = ""
              in_term = false
     
              in_bracket = (c == "{")
            end
     
            if in_bracket && (!"{}".include? c)
              term += c
              in_term = true
            else
     
              case c
              when "{"
                in_bracket = true
              when "}"
                in_bracket = false
              when "("
                sql += c
              when ")"
                sql += c
              when "+"
                sql += " AND " if sql.last != "("
              when "~"
                sql += " OR " if sql.last != "("
              when "!"
                sql += " NOT "
              else
                if c != " "
                  term += c
                  in_term = true
                end
              end
     
            end
          end
     
          if operator.include? "!"
            sql = " NOT " + sql
          end
     
          Rails.logger.info "MATCH EXPRESSION: V=#{value.first}, SQL=#{sql}"
          return sql
        end
 
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
          
          and_clauses = []
          and_any_clauses = []
          or_any_clauses = []
          or_all_clauses = []
          and_any_op = ""
          or_any_op = ""
          or_all_op = ""

          #the AND filter start first
          filters_clauses = and_clauses
          
          filters.each_key do |field|
            next if field == "subproject_id"
            
            if field == "and_any"
              #start the and any part, point filters_clause to and_any_clauses
              filters_clauses = and_any_clauses
              and_any_op = operator_for(field) == "=" ? " AND " : " AND NOT "
              next
            elsif field == "or_any"
              #start the or any part, point filters_clause to or_any_clauses
              filters_clauses = or_any_clauses
              or_any_op = operator_for(field) == "=" ? " OR " : " OR NOT "
              next
            elsif  field == "or_all"
              #start the or any part, point filters_clause to or_any_clauses
              filters_clauses = or_all_clauses
              or_all_op = operator_for(field) == "=" ? " OR " : " OR NOT "
              next
            end
            
            v = values_for(field).clone
            next unless v and !v.empty?
            operator = operator_for(field)
      
            # "me" value substitution
            if %w(assigned_to_id author_id user_id watcher_id updated_by last_updated_by).include?(field)
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

          #now start build the full statement, project filter is allways AND
          and_clauses.reject!(&:blank?)
          and_statement = and_clauses.any? ? and_clauses.join(" AND ") : nil

          all_and_statement = ["#{project_statement}", "#{and_statement}"].reject(&:blank?)
          all_and_statement = all_and_statement.any? ? all_and_statement.join(" AND ") : nil

          # finish the traditional part. Now extended part
          # add the and_any first
          and_any_clauses.reject!(&:blank?)
          and_any_statement = and_any_clauses.any? ? "("+ and_any_clauses.join(" OR ") +")" : nil

          full_statement_ext_1 = ["#{all_and_statement}", "#{and_any_statement}"].reject(&:blank?)
          full_statement_ext_1 = full_statement_ext_1.any? ? full_statement_ext_1.join(and_any_op) : nil

          # then add the or_all
          or_all_clauses.reject!(&:blank?)
          or_all_statement = or_all_clauses.any? ? "("+ or_all_clauses.join(" AND ") +")" : nil

          # then add the or_any
          or_any_clauses.reject!(&:blank?)
          or_any_statement = or_any_clauses.any? ? "("+ or_any_clauses.join(" OR ") +")" : nil

          full_statement_ext_2 = ["#{full_statement_ext_1}", "#{or_all_statement}"].reject(&:blank?)
          full_statement_ext_2 = full_statement_ext_2.any? ? full_statement_ext_2.join(or_all_op) : nil
        
          #filters_clauses.any? ? filters_clauses.join(' AND ') : nil
    
          full_statement = ["#{full_statement_ext_2}", "#{or_any_statement}"].reject(&:blank?)
          full_statement = full_statement.any? ? full_statement.join(or_any_op) : nil

          Rails.logger.info "STATEMENT #{full_statement}"

          return full_statement          
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



