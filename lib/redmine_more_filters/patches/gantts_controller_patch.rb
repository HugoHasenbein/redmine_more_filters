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
    module GanttsControllerPatch
      def self.included(base)
        
        base.class_eval do
          unloadable
          
          def show
            @gantt = Redmine::Helpers::Gantt.new(params)
            @gantt.project = @project
            retrieve_query
            @query.group_by = nil
            if @query.valid?
              @gantt.query = @query
              if params[:x].present? # x -> center_last_due_date
                set_gantt_dates 
              end
            end
            
            basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
            
            respond_to do |format|
              format.html { render :action => "show", :layout => !request.xhr? }
              format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
              format.pdf  { send_data(@gantt.to_pdf, :type => 'application/pdf', :filename => "#{basename}.pdf") }
            end
          end #def
          
          def set_gantt_dates
            due_date     = @gantt.issues.map(&:due_date).compact.max
            start_date   = @gantt.issues.map(&:start_date).compact.min
            if due_date && start_date
              due_date   = due_date.advance(:months => 1)
              months     = (due_date.month+due_date.year*12) - (start_date.month+start_date.year*12)
              # gantt_months_limit is not available in earlier versions of redmine
              months     = [months, (Setting.try(:gantt_months_limit) || 36).to_i].min
              from       = due_date.advance(:months => -months)
              month_from = from.month
              year_from  = from.year
              date_from  = Date.civil(year_from, month_from, 1)
              date_to    = (date_from >> months) - 1
              @gantt.month_from, @gantt.year_from, @gantt.date_from, @gantt.date_to, @gantt.months =
                     month_from,        year_from,        date_from,        date_to,        months
            end
          end #def
          private :set_gantt_dates
          
        end #base
      end #self
      
    end #module
  end #module
end #module

unless GanttsController.included_modules.include?(RedmineMoreFilters::Patches::GanttsControllerPatch)
  GanttsController.send(:include, RedmineMoreFilters::Patches::GanttsControllerPatch)
end



