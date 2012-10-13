fluent-plugin-mysql-query
===========================

Fluentd Input plugin to execute mysql command intervaled.

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
  record_hostname yes                 # Optional (yes/no)
</source>

<match input.mysql>
  type stdout
</match>
`````

### Output Sample
`````
input.mysql: {"hostname":"myhost.example.com","Variable_name":"thread_cache_size","Value":"16"}
input.mysql: {"hostname":"myhost.example.com","Variable_name":"thread_stack","Value":"262144"}
`````

## TODO
patches welcome!
* support results into array option
* support result_key_downcase option

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
