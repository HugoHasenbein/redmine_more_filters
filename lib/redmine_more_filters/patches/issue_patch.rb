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
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
        end #base
      end #self
      
      module InstanceMethods
      
        def created_on_by_clock_time
          created_on.in_time_zone(User.current.time_zone_or_default_identifier).strftime("%H").to_i
        end #def
        
        def updated_on_by_clock_time
          updated_on.in_time_zone(User.current.time_zone_or_default_identifier).strftime("%H").to_i
        end #def
        
      end #module
    end #module
  end #module
end #module

unless Issue.included_modules.include?(RedmineMoreFilters::Patches::IssuePatch)
  Issue.send(:include, RedmineMoreFilters::Patches::IssuePatch)
end



