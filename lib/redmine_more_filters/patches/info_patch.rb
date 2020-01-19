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
    module InfoPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
        base.class_eval do
          unloadable
          
          def self.environment_with_db_info
          
            s = environment_without_db_info
            a = s.split(/\n/)
            
            begin
              db = [
                ["Database timezone",    Redmine::Database.db_timezone],
                ["ActiveRecord timezone", RedmineApp::Application.config.active_record.default_timezone.to_s],
                ["App timezone",   RedmineApp::Application.config.time_zone]
              ].map {|info| "  %-30s %s" % info}
            rescue Exception => e
              db = [
                ["Database timezone",    e.message.gsub(/n/, " ")],
                ["ActiveRecord timezone", RedmineApp::Application.config.active_record.default_timezone.to_s],
                ["App timezone",   RedmineApp::Application.config.time_zone]
              ].map {|info| "  %-30s %s" % info}
            end
            
            a.insert(6, db).flatten!
            a.join("\n")
          
          end #def
          
          self.singleton_class.send(:alias_method, :environment_without_db_info, :environment)
          self.singleton_class.send(:alias_method, :environment, :environment_with_db_info   )
          
        end #base
      end #self
      
      module InstanceMethods
      end #module
      
      module ClassMethods
      end #module
      
    end #module
  end #module
end #module

unless Redmine::Info.included_modules.include?(RedmineMoreFilters::Patches::InfoPatch)
  Redmine::Info.send(:include, RedmineMoreFilters::Patches::InfoPatch)
end



