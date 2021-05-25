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
# 1.1.1
#       - added one_of and none_of for strings
# 1.2.0
#       - added AND for Date/Value custom fields
# 1.2.1 
#       - made AND for Date/Value custom fields more strict
# 1.2.2
#       - changed list custom field from :list_optional to new type :list_multiple
# 1.2.3
#       - added contains all and does not contain all for list_multiple
# 1.3.0
#       - added Rails 5 support
# 1.3.1
#       - added support for arbitrary separators for id field
# 1.3.2
#       - modified "all" filter for text and string to not match empty / whitespace values
# 1.3.3
#       - bugfix: sql_for_custom_field aliases for Rails 5+
# 1.3.4
#       - bugfix: sql_for_custom_field crashed when used with certain other plugins
# 1.4.0
#       - support for local time (irrespectively of date) searches (supporting daylight savings)
#         to use with
#         
#           postgres: 
#                  timezone support is built in
#               
#           mysql: you need to load the time zone tables first f.i. with
#                  `mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql -u root -p`
#                  
#           sqlserver:
#                  you must install https://github.com/mj1856/SqlServerTimeZoneSupport
#                  to your database for this plugin to work. 
#                  
# 1.4.1
#       - supports search text in notes, filename, description, author and creation time of attachments
#
# 1.4.2
#       - compatible with RedmineUp's redmine CRM plugin
#
# 1.4.3
#       - added root issue         filter
#       - added related issues     filter
#       - added all related issues filter
#       - added Gantt link in Subtask pane, Related Task pane and in Issue's action menu
#       - added Gantt link in Issue context menu
#       - added Gantt auto centering of Gantt charts for Gantt links
#       - added next three months for date queries
#       - added localizations: es, fr, ru, pt
#
# 1.4.4
#       - added missing translation for "root"
#
require 'redmine'

Redmine::Plugin.register :redmine_more_filters do
  name 'Redmine More Filters'
  author 'Stephan Wenzel'
  description 'Plugin to add necessary filters to queries'
  version '1.4.4'
  url 'https://github.com/HugoHasenbein/redmine_more_filters'
  author_url 'https://github.com/HugoHasenbein/redmine_more_filters'

end

require "redmine_more_filters"

