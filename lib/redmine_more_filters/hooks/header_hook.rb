module RedmineMoreFilters
  module Hooks
    class HeaderHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_html_head, :partial => 'hooks/redmine_more_filters/toggle_operator', :layout => false
    end
  end
end