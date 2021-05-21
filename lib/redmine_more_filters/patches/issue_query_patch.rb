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
            ),
            QueryColumn.new(:root, 
              :sortable  => "#{Issue.table_name}.root_id", :default_order => 'desc',
              :groupable => true
            )
          ]
          
        end #base
      end #self
      
      module InstanceMethods
      
        def initialize_available_filters_with_more_filters
        
          initialize_available_filters_without_more_filters
          
          add_available_filter "root_id", 
            :type  => :integer, 
            :label => :field_root
            
          add_available_filter "any_relation", 
            :type  => :relation, 
            :values => lambda {all_projects_values},
            :label => :label_related_issues
            
          add_available_filter "all_relations", 
            :type  => :integer, 
            :label => :label_all_relations
            
          add_available_filter("created_on_by_clock_time",
            :type => :time_past
          )
          
          add_available_filter("updated_on_by_clock_time",
            :type => :time_past
          )
          
          add_available_filter("notes",
            :type => :text
          )
          
          add_available_filter("attachment_filename",
            :type => :string
          )
          
          add_available_filter("attachment_created_on",
            :type => :date_past
          )
          
          add_available_filter("attachment_created_on_by_clock_time",
            :type => :time_past
          )
          
          add_available_filter("attachment_description",
            :type => :string
          )
          
          add_available_filter("attachment_author_id",
            :type => :list, :values => lambda { author_values }
          )
        end #def
        
        def sql_for_created_on_by_clock_time_field(field, operator, value)
          sql_for_field( field, operator, value, Issue.table_name, 'created_on' )
        end #def
        
        def sql_for_updated_on_by_clock_time_field(field, operator, value)
          sql_for_field( field, operator, value, Issue.table_name, 'updated_on' )
        end #def
        
        def sql_for_notes_field(field, operator, value)
          subquery = "SELECT 1 FROM #{Journal.table_name}" +
            " WHERE #{Journal.table_name}.journalized_type='Issue' AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id" +
            " AND (#{Journal.visible_notes_condition(User.current, :skip_pre_condition => true)})" +
            " AND (#{sql_for_field field, operator, value, Journal.table_name, 'notes'})" 
            
          "EXISTS (#{subquery})"
        end #def
        
        def sql_for_attachment_filename_field(field, operator, value)
          subquery = "SELECT 1 FROM #{Attachment.table_name}" +
            " WHERE #{Attachment.table_name}.container_type='Issue' AND #{Attachment.table_name}.container_id=#{Issue.table_name}.id" +
            " AND (#{sql_for_field field, operator, value, Attachment.table_name, 'filename'})" 
            
          "EXISTS (#{subquery})"
        end #def
        
        def sql_for_attachment_description_field(field, operator, value)
          subquery = "SELECT 1 FROM #{Attachment.table_name}" +
            " WHERE #{Attachment.table_name}.container_type='Issue' AND #{Attachment.table_name}.container_id=#{Issue.table_name}.id" +
            " AND (#{sql_for_field field, operator, value, Attachment.table_name, 'description'})" 
            
          "EXISTS (#{subquery})"
        end #def
        
        def sql_for_attachment_created_on_field(field, operator, value)
          subquery = "SELECT 1 FROM #{Attachment.table_name}" +
            " WHERE #{Attachment.table_name}.container_type='Issue' AND #{Attachment.table_name}.container_id=#{Issue.table_name}.id" +
            " AND (#{sql_for_field field, operator, value, Attachment.table_name, 'created_on'})" 
            
          "EXISTS (#{subquery})"
        end #def
        
        def sql_for_attachment_created_on_by_clock_time_field(field, operator, value)
          subquery = "SELECT 1 FROM #{Attachment.table_name}" +
            " WHERE #{Attachment.table_name}.container_type='Issue' AND #{Attachment.table_name}.container_id=#{Issue.table_name}.id" +
            " AND (#{sql_for_field field, operator, value, Attachment.table_name, 'created_on'})" 
            
          "EXISTS (#{subquery})"
        end #def
        
        def sql_for_attachment_author_id_field(field, operator, value)
          subquery = "SELECT 1 FROM #{Attachment.table_name}" +
            " WHERE #{Attachment.table_name}.container_type='Issue' AND #{Attachment.table_name}.container_id=#{Issue.table_name}.id" +
            " AND (#{sql_for_field field, operator, value, Attachment.table_name, 'author_id'})" 
            
          "EXISTS (#{subquery})"
        end #def
        
        def sql_for_any_relation_field(field, operator, value, options={})
        
          join_column, target_join_column = "issue_from_id", "issue_to_id"
          if options[:reverse]
            join_column, target_join_column = target_join_column, join_column
          end
          
          sql =
            case operator
            when "*", "!*"
              op = (operator == "*" ? 'IN' : 'NOT IN')
              "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name})"
            when "=", "!"
              op = (operator == "=" ? 'IN' : 'NOT IN')
              "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.#{target_join_column} = #{value.first.to_i})"
            when "=p", "=!p", "!p"
              op = (operator == "!p" ? 'NOT IN' : 'IN')
              comp = (operator == "=!p" ? '<>' : '=')
              "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.project_id #{comp} #{value.first.to_i})"
            when "*o", "!o"
              op = (operator == "!o" ? 'NOT IN' : 'IN')
              "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.status_id IN (SELECT id FROM #{IssueStatus.table_name} WHERE is_closed=#{self.class.connection.quoted_false}))"
            end
          if !options[:reverse]
            sqls = [sql, sql_for_any_relation_field(field, operator, value, :reverse => true)]
            sqls << sql_for_field("id", "=", value, Issue.table_name, 'id') if ["="].include?(operator)
            sql = sqls.join(["!", "!*", "!p", '!o'].include?(operator) ? " AND " : " OR ")
          end
          "(#{sql})"
        end
        
        def sql_for_all_relations_field(field, operator, value, options={})
        
          join_column, target_join_column = "issue_from_id", "issue_to_id"
          if options[:reverse]
            join_column, target_join_column = target_join_column, join_column
          end
          
          int_sql   = sql_for_field('all_relations', operator, value, "rels", target_join_column)
          issue_sql = sql_for_field('all_relations', operator, value, Issue.table_name, 'id')
          sql = "(#{Issue.table_name}.root_id IN ( SELECT DISTINCT #{Issue.table_name}.root_id FROM #{Issue.table_name}, #{IssueRelation.table_name} rels WHERE #{Issue.table_name}.id = rels.#{join_column} AND #{int_sql} ) OR " +
                " #{Issue.table_name}.root_id IN ( SELECT DISTINCT #{Issue.table_name}.root_id FROM #{Issue.table_name} WHERE #{issue_sql} ))"
          if !options[:reverse]
            sqls = [sql, sql_for_all_relations_field(field, operator, value, :reverse => true)]
            sql = sqls.join(["="].include?(operator) ? " OR " : " AND ")
          end
          "(#{sql})"
        end
        
      end #module
    end #module
  end #module
end #module

unless IssueQuery.included_modules.include?(RedmineMoreFilters::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineMoreFilters::Patches::IssueQueryPatch)
end



