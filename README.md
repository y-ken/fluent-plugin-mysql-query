fluent-plugin-mysql-query [![Build Status](https://travis-ci.org/y-ken/fluent-plugin-mysql-query.png?branch=master)](https://travis-ci.org/y-ken/fluent-plugin-mysql-query)
===========================

Fluentd Input plugin to execute mysql query and fetch rows. It is useful for stationary interval metrics measurement.

## Installation

### native gem

`````
gem install fluent-plugin-mysql-query
`````

### td-agent gem
`````
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-mysql-query
`````

## Configuration

### Config Sample
`````
<source>
  type            mysql_query
  host            localhost           # Optional (default: localhost)
  port            3306                # Optional (default: 3306)
  username        nagios              # Optional (default: root)
  password        passw0rd            # Optional (default nopassword)
  interval        30s                 # Optional (default: 1m)
  tag             input.mysql         # Required
  query           SHOW VARIABLES LIKE 'Thread_%' # Required
  # record hostname into message.
  record_hostname yes                 # Optional (default: no)
  # multi row results into nested record or separated message.
  nest_result     yes                 # Optional (default: no)
  nest_key        data                # Optional (default: result)
  # record the number of lines of a query result
  row_count       yes                 # Optional (default: no)
  row_count_key   row_count           # Optional (default: row_count)
</source>

<match input.mysql>
  type stdout
</match>
`````

### Output Sample
record_hostname: yes, nest_result: no
`````
input.mysql: {"hostname":"myhost.example.com","Variable_name":"thread_cache_size","Value":"16"}
input.mysql: {"hostname":"myhost.example.com","Variable_name":"thread_stack","Value":"262144"}
`````
record_hostname: yes, nest_result: yes, nest_key: data
`````
input.mysql: {"hostname":"myhost.example.com","data":[{"Variable_name":"thread_cache_size","Value":"16"},{"Variable_name":"thread_stack","Value":"262144"}]}
`````
record_hostname: yes, nest_result: yes, nest_key: data, row_count: yes, row_count_key: row_count
`````
input.mysql: {"hostname":"myhost.example.com","row_count":2,"data":[{"Variable_name":"thread_cache_size","Value":"16"},{"Variable_name":"thread_stack","Value":"262144"}]}
`````

### Example Query
* SHOW VARIABLES LIKE 'Thread_%';
* SELECT MAX(id) AS max_foo_id FROM foo_table;
* SHOW FULL PROCESSLIST;
* INSERT INTO log (data, created_at) VALUES((SELECT MAX(id) FROM foo_table), NOW());
* SHOW SLAVE STATUS;
* SHOW INNODB STATUS; -- MySQL 5.0
* SHOW ENGINE INNODB STATUS; -- MySQL 5.5 or later

## TODO
patches welcome!
* support result_key_downcase option

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
