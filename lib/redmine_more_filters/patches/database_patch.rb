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
    module DatabasePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
        
        base.class_eval do
          unloadable
          
        end #base
      end #self
      
      module InstanceMethods
      end
      
      module ClassMethods
        # Returns true if the database is a SQLServer
        def sqlserver?
          (ActiveRecord::Base.connection.adapter_name =~ /SQLServer/i).present?
        end
        
        # Returns a SQL statement for relative time
        def relative_time( num, epoch )
          if postgresql?
            "(CURRENT_TIMESTAMP + INTERVAL '#{num} #{epoch}')"
          elsif mysql?
            "(CURRENT_TIMESTAMP + INTERVAL #{num} #{epoch})"
          elsif sqlserver?
            "(DATEADD(#{epoch}, #{num}, CURRENT_TIMESTAMP))"
          end
        end #def
        
        # Returns a SQL statement for local time
        def local_time_sql( table_name, field, time_zone )
          
          if postgresql?
            "#{table_name}.#{field} at time zone '#{db_timezone.downcase}' at time zone '#{time_zone.downcase}'"
          elsif mysql?
            "CONVERT_TZ(#{table_name}.#{field}, '#{db_timezone.downcase}', '#{time_zone.downcase}')"
          elsif sqlserver?
            "Tzdb.ConvertZone(#{table_name}.#{field}, '#{db_timezone}', '#{time_zone}', 1, 1)"
          end
        end #def
        
        # Returns a SQL statement for hour of local clock time
        def local_clock_time_sql( table_name, field, time_zone )
          "CAST(#{local_time_sql(table_name, field, time_zone)} AS TIME)"
        end #def
        
        # Returns a SQL statement for hour of local time
        def hour_of_local_clock_time_sql( table_name, field, time_zone )
          if postgresql?   
            "CAST(DATE_PART('hour', #{local_clock_time_sql( table_name, field, time_zone)} ) AS INTEGER)"
          elsif mysql?
            "CAST(hour(#{local_clock_time_sql( table_name, field, time_zone)}) AS INTEGER)"
          elsif sqlserver?
            "CAST(DATEPART('hour', #{local_clock_time_sql( table_name, field, time_zone)}) AS INTEGER)"
          else
            nil
          end
        end #def
        
        # Returns a SQL statement for month of date
        def month_of_date_sql( table_name, field, time_zone )
          if postgresql?   
            "EXTRACT(MONTH FROM #{local_clock_time_sql( table_name, field, time_zone)})"
          elsif mysql?
            "MONTH( #{local_clock_time_sql( table_name, field, time_zone)} )"
          elsif sqlserver?
            "MONTH( #{local_clock_time_sql( table_name, field, time_zone)} )"
          else
            nil
          end
        end #def
        
        # Returns a SQL statement for month of date
        def year_of_date_sql( table_name, field, time_zone )
          if postgresql?   
            "EXTRACT(YEAR FROM #{local_clock_time_sql( table_name, field, time_zone)})"
          elsif mysql?
            "YEAR( #{local_clock_time_sql( table_name, field, time_zone)} )"
          elsif sqlserver?
            "YEAR( #{local_clock_time_sql( table_name, field, time_zone)} )"
          else
            nil
          end
        end #def
        
        # Returns a SQL statement for month of date
        def date_diff_sql( table_name, start_field, end_field )
          if postgresql?   
            "CAST(#{table_name}.#{end_field} - #{table_name}.#{start_field} as INTEGER)"
          elsif mysql?
            "DATEDIFF(#{table_name}.#{end_field}, #{table_name}.#{start_field})"
          elsif sqlserver?
            "DATEDIFF(dd, #{table_name}.#{start_field}, #{table_name}.#{end_field})"
          else
            nil
          end
        end #def
        
        # Returns a SQL statement for month of date
        def ago_sql( table_name, field )
          if postgresql?   
            "CAST( CURRENT_DATE - #{table_name}.#{field})"
          elsif mysql?
            "DATEDIFF(CURRENT_DATE(), #{table_name}.#{field})"
          elsif sqlserver?
            "DATEDIFF(dd, #{table_name}.#{field}, GETDATE())"
          else
            nil
          end
        end #def
        
        def query_db_timezone
          sql = 
          if postgresql?
            "SELECT current_setting('TIMEZONE');"
          elsif mysql?
            "SELECT @@system_time_zone;"
          elsif sqlserver?
            "EXEC MASTER.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation','TimeZoneKeyName'"
          else
            nil
          end
          
          if sql
            result = ActiveRecord::Base.connection.exec_query(sql).rows[0]
          end
          
          timezone = 
          if result.present?
            if postgresql?
              result[0]
            elsif mysql?
              result[0]
            elsif sqlserver?
              result[1]
            else
              nil
            end
          else
            nil
          end
          
        end #def
        
        def db_timezone
          @db_timezone ||= query_db_timezone
        end #def
        
      end
    end
  end
end

unless Redmine::Database.included_modules.include?(RedmineMoreFilters::Patches::DatabasePatch)
  Redmine::Database.send(:include, RedmineMoreFilters::Patches::DatabasePatch)
end



