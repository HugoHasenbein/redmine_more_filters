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
  module Hooks
    class IssueContextMenu < Redmine::Hook::ViewListener
      def view_issues_context_menu_end(context={ })
        context[:controller].send(:render_to_string, {
          :partial => 'hooks/redmine_more_filters/issues_context_menu',
          :locals => context
        }) if context[:issues].all?{|issue| issue.project.module_enabled?(:gantt)}
      end
      #render_on :view_issues_show_description_bottom, :partial => 'hooks/redmine_more_filters/issue_show'
    end
  end
end