fluent-plugin-mysql-query
===========================

Fluentd Input plugin to execute mysql query for stationary measurement.

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
  server          localhost           # Optional (default: localhost)
  port            3306                # Optional (default: 3306)
  username        nagios              # Optional (default: root)
  password        passw0rd            # Optional (default nopassword)
  interval        30s                 # Optional (default: 1m)
  tag             input.mysql         # Required
  query           SHOW VARIABLES LIKE 'Thread_%' # Required
  # inserting hostname into record.
  record_hostname yes                 # Optional (yes/no)
  # multi row results to be nested or separated record.
  nest_result     no                  # Optional (yes/no)
  nest_keyname    data                # Optional (default: result)
</source>

<match input.mysql>
  type stdout
</match>
`````

### Output Sample
record_hostname: no, nest_result: no
`````
input.mysql: {"hostname":"myhost.example.com","Variable_name":"thread_cache_size","Value":"16"}
input.mysql: {"hostname":"myhost.example.com","Variable_name":"thread_stack","Value":"262144"}
`````
record_hostname: no, nest_result: yes, nest_keyname: data
`````
input.mysql: {"hostname":"myhost.example.com","data":[{"Variable_name":"thread_cache_size","Value":"16"},{"Variable_name":"thread_stack","Value":"262144"}]}
`````

### Query Example
* SHOW VARIABLES LIKE 'Thread_%';
* SELECT MAX(id) AS max_foo_id FROM foo_table;
* SHOW FULL PROCESSLIST;

## TODO
patches welcome!
* support result_key_downcase option

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
