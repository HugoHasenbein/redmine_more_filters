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
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
          def time_zone_or_default_identifier
            return time_zone.tzinfo.canonical_identifier if time_zone
            if RedmineApp::Application.config.time_zone && ActiveSupport::TimeZone[RedmineApp::Application.config.time_zone]
              return ActiveSupport::TimeZone[RedmineApp::Application.config.time_zone].tzinfo.canonical_identifier 
            end
            return "Etc/UTC"
          end
          
        end #base
      end #self
      
      module InstanceMethods
      end #module
      
    end #module
  end #module
end #module

unless User.included_modules.include?(RedmineMoreFilters::Patches::UserPatch)
  User.send(:include, RedmineMoreFilters::Patches::UserPatch)
end



