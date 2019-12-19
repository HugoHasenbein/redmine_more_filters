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
|---––––-|------------|----------|
|String  |begins_with||
|        |begins_with_any|   (supply list of whitespace separated words)|
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
|Date    |tomorrow||
|        |next_week||
|        |next_month||
|List Custom Field (Multiple Values)|is (strict)| (select values in list)|
|List Custom Field (Multiple Values)|is not (strict)| s(elect values in list)|


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

**1.1.0**
  - added more text filters by popular request

**1.0.2** 
  - beautified code


**0.0.1** 
  - running on Redmine 3.4.6, 3.4.11
