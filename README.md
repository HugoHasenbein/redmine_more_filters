# redmine_more_filters

Redmine plugin tp provide necessary filters in queries

### Use case(s)

For date filters with future dates, the plugin adds "tomorrow", "next week" and "next" month

![PNG that represents a quick overview](/doc/new_date_filters.png)

For string and text filters, the plugin adds "begins with", "does not begin with", "ends with", "does not end with"

![PNG that represents a quick overview](/doc/new_string_and_text_filters.png)


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

**1.0.2** 
  - beautified code


**0.0.1** 
  - running on Redmine 3.4.6, 3.4.11
