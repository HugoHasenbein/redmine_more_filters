# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)

class QueryTest < ActiveSupport::TestCase
  include Redmine::I18n

  fixtures :projects, :enabled_modules, :users, :members,
           :member_roles, :roles, :trackers, :issue_statuses,
           :issue_categories, :enumerations, :issues,
           :watchers, :custom_fields, :custom_values, :versions,
           :queries,
           :projects_trackers,
           :custom_fields_trackers,
           :workflows, :journals,
           :attachments

  INTEGER_KLASS = RUBY_VERSION >= "2.4" ? Integer : Fixnum

  def setup
    User.current = nil
  end

  def test_filter_on_subject_match
    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => 'match', :values => ['issue']}}
    issues = find_issues_with_query(query)
    assert_equal [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], issues.collect(&:id).sort

    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => 'match', :values => ['(~project ~recipe) +!sub']}}
    issues = find_issues_with_query(query)
    assert_equal [1, 3, 4, 14], issues.collect(&:id).sort

    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => 'match', :values => ['!(~sub project ~block) +issue']}}
    issues = find_issues_with_query(query)
    assert_equal [4, 7, 8, 11, 12, 14], issues.collect(&:id).sort

    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => 'match', :values => ['+{closed ver} ~{locked ver}']}}
    issues = find_issues_with_query(query)
    assert_equal [11, 12], issues.collect(&:id).sort
  end

  def test_filter_on_subject_not_match
    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => '!match', :values => ['issue']}}
    issues = find_issues_with_query(query)
    assert_equal [1, 2, 3], issues.collect(&:id).sort

    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => '!match', :values => ['(~project ~recipe) +!sub']}}
    issues = find_issues_with_query(query)
    assert_equal [2, 5, 6, 7, 8, 9, 10, 11, 12, 13], issues.collect(&:id).sort

    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => '!match', :values => ['!(~sub project ~block) +issue']}}
    issues = find_issues_with_query(query)
    assert_equal [1, 2, 3, 5, 6, 9, 10, 13], issues.collect(&:id).sort

    query = IssueQuery.new(:name => '_')
    query.filters = {'subject' => {:operator => '!match', :values => ['+{closed ver} ~{locked ver}']}}
    issues = find_issues_with_query(query)
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14], issues.collect(&:id).sort
  end

  def test_filter_on_orfilter_and_any
    query = IssueQuery.new(:name => '_')
    query.filters = {'project_id' => {:operator => '=', :values => [1]},
                     'and_any' => {:operator => '=', :values => [1]},
                     'status_id' => {:operator => '!', :values => [1]},
                     'assigned_to_id' => {:operator => '=', :values => [3]}}
    issues = find_issues_with_query(query)
    assert_equal [2, 3, 8, 11, 12], issues.collect(&:id).sort
  end

  def test_filter_on_orfilter_and_any_not
    query = IssueQuery.new(:name => '_')
    query.filters = {'project_id' => {:operator => '=', :values => [1]},
                     'and_any' => {:operator => '!', :values => [1]},
                     'status_id' => {:operator => '=', :values => [2]},
                     'author_id' => {:operator => '=', :values => [3]}}
    issues = find_issues_with_query(query)
    assert_equal [1, 3, 7, 8, 11], issues.collect(&:id).sort
  end

  def test_filter_on_orfilter_or_any
    query = IssueQuery.new(:name => '_')
    query.filters = {'status_id' => {:operator => '!', :values => [1]},
                     'or_any' => {:operator => '=', :values => [1]},
                     'project_id' => {:operator => '=', :values => [3]},
                     'assigned_to_id' => {:operator => '=', :values => [2]}}
    issues = find_issues_with_query(query)
    assert_equal [2, 4, 5, 8, 11, 12, 13, 14], issues.collect(&:id).sort
  end

  def test_filter_on_orfilter_or_any_not
    query = IssueQuery.new(:name => '_')
    query.filters = {'status_id' => {:operator => '!', :values => [1]},
                     'or_any' => {:operator => '!', :values => [1]},
                     'project_id' => {:operator => '=', :values => [3]},
                     'assigned_to_id' => {:operator => '!', :values => [2]}}
    issues = find_issues_with_query(query)
    assert_equal [2, 4, 8, 11, 12], issues.collect(&:id).sort
  end

  def test_filter_on_orfilter_or_all
    query = IssueQuery.new(:name => '_')
    query.filters = {'project_id' => {:operator => '=', :values => [3]},
                     'or_all' => {:operator => '=', :values => [1]},
                     'author_id' => {:operator => '=', :values => [2]},
                     'assigned_to_id' => {:operator => '=', :values => [2]}}
    issues = find_issues_with_query(query)
    assert_equal [4, 5, 13, 14], issues.collect(&:id).sort
  end

  def test_filter_on_orfilter_or_all_not
    query = IssueQuery.new(:name => '_')
    query.filters = {'project_id' => {:operator => '=', :values => [3]},
                     'or_all' => {:operator => '!', :values => [1]},
                     'author_id' => {:operator => '=', :values => [2]},
                     'assigned_to_id' => {:operator => '=', :values => [2]}}
    issues = find_issues_with_query(query)
    assert_equal [2, 3, 5, 12, 13, 14], issues.collect(&:id).sort
  end

end
