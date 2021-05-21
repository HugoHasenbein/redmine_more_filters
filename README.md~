# redmine_more_filters

Redmine plugin to provide necessary filters in queries

### Use case(s)

For date filters with future dates, the plugin adds "tomorrow", "next week" and "next" month

![PNG that represents a quick overview](/doc/new_date_filters.png)

For string and text filters, the plugin adds "begins with", "does not begin with", "ends with", "does not end with"

![PNG that represents a quick overview](/doc/new_string_and_text_filters.png)

### version 1.1.0

By poular request I added even more filters

currently available filters:

|Type    |Filter      |Value     |
|---|---|---|
|String  |begins_with||
|        |begins_with_any|    (supply list of whitespace separated words)|
|        |not_begins_with||  
|        |not_begins_with_any| (supply list of whitespace separated words)|
|        |||
|        |ends_with||
|        |ends_with_any|       (supply list of whitespace separated words)|
|        |not_ends_with||
|        |not_ends_with_any|   (supply list of whitespace separated words)|
|        |||
|        |contains_any|        (supply list of whitespace separated words)|
|        |not_contains_any|    (supply list of whitespace separated words)|
|        |contains_all|        (supply list of whitespace separated words)|
|        |not_contains_all|    (supply list of whitespace separated words)|
|        |||
|Integer ||allow any separator other than '+' or '-' between two integers|
|Date    |tomorrow||
|        |next_week||
|        |next_month||
|List Custom Field (Multiple Values)|is (strict)| (select values in list)|
|        |contains all|  (select values in list)|
|        |is not (strict)| (select values in list)|
|        |not contains all| (select values in list)|
|Time    |less than hours ago|input number of hours|
|        |more than hours ago|input number of hours|
|        |between ago|input numbers of hours (start-end)|
|        |between|input clock times (start-end)|
|        |passed||

The new Time filters work on the issue fields "Created On" and "Updated On". 

The "passed" filter is very much alike the existing date filter "<=" and toda'y date. However, this filter can be saved without having to update today's date. Further, it will find issues having a creation time or update time only one second ago.

The between clock times filter filters issues irrespectively of the date. If you want to filter clock times of today's date you can add the exsting filter "Updated" or "Created" today.

By grouping issues by the hour (local time aware, local daylight savings aware) you can easily identify the "productive" hour and the "blue hour" of your team. 

You can also filter last hour's issues, if Redmine is used in a call center.

Be aware that switching time zones may give surprising results with respect to grouping by local clock time hours. Daylight savings transistions occur at different times in different countries. The grouping is local time aware and groups issues by the creation or update hour of the day.

In Administration->Info you find the configured default timezones for the database, for Rails ActiveRecord and for Redmine. If you run in problems, please check here first.

This plugin has been tested with posstgres. MySQL should run. It also should run on SQLServer, but it has not been tested. Please be aware, that timezone support varies extremely between different databases.

#### PostgrSQL

Timezone support is built in

#### MySQL

Need to load the time zone tables first f.i. from the commandline outside of mysql

`mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql -u root -p`

#### SQLServer

Thereis only little support for timezones in SQLServer

There is a persistently loadable SQL function available

  https://github.com/mj1856/SqlServerTimeZoneSupport

You MUST install this SQLServer function to your database for this plugin to work with timezone grouping 


### Install

1. download plugin and copy plugin folder redmine_user_text_box to Redmine's plugins folder 

2. restart server f.i.  

`sudo /etc/init.d/apache2 restart`

(no migration is necessary)

### Uninstall

1. go to plugins folder, delete plugin folder  

`rm -r redmine_more_filters`

2. restart server f.i. 

`sudo /etc/init.d/apache2 restart`

### Use

Just install and go to issue page and select a date field with future dates, or a text or a atring fiter

**Have fun!**

### Localisations

* German
* English
* Chinese

**1.4.2**
  - compatible with RedmineUp's redmine CRM plugin
  
**1.4.1**
  - supports search text in notes, filename, description, author and creation time of attachments

**1.4.0**
  - added more time filters
  - time filters supported for postgres (tested), MySQL (untested) and SQLServer (untested)
  - added database timezone info in Administration->Info

**1.3.1**
  - added support for arbitrary separators for integer (like ID) "=", like 123;456 789

**1.3.0** 
  - added Rails 5 support

**1.2.3**
  - added "contains all" and "not contains all"  for list custom fields having mutiple values
  
**1.2.2**
  - added strict "is" and "is not" filter for list custom fields having mutiple values (basically acting like boolean "AND") in addition to "is" and "is not" (basically acting like boolean "OR")

**1.1.0**
  - added more text filters by popular request

**1.0.2** 
  - beautified code

**0.0.1** 
  - running on Redmine 3.4.6, 3.4.11
