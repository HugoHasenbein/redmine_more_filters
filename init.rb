# encoding: utf-8
#
# Redmine plugin to add necessary filters to queries
#
# Copyright © 2019 Stephan Wenzel <stephan.wenzel@drwpatent.de>
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

require 'redmine'

Redmine::Plugin.register :redmine_more_filters do
  name 'Redmine More Filters'
  author 'Stephan Wenzel'
  description 'Plugin to add necessary filters to queries'
  version '1.3.1'
  url 'https://github.com/HugoHasenbein/redmine_more_filters'
  author_url 'https://github.com/HugoHasenbein/redmine_more_filters'

end

require "redmine_more_filters"

