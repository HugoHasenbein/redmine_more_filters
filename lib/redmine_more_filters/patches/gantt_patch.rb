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
    module GanttPatch
      def self.included(base)
        
        base.class_eval do
          
          attr_writer :year_from, :month_from, :date_from, :date_to, :zoom, :months, :truncated, :max_rows
          
        end #base
      end #self
      
    end #module
  end #module
end #module

unless Redmine::Helpers::Gantt.included_modules.include?(RedmineMoreFilters::Patches::GanttPatch)
  Redmine::Helpers::Gantt.send(:include, RedmineMoreFilters::Patches::GanttPatch)
end



