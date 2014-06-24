# Kafka Debian Packaging

## Requirements

 * Ruby
 * Ruby gems: bundler

## Usage


```shell

  $ bundle install
  $ thor kafka:build

```

currently support checkout of git tags

```
thor kafka:build --version 0.8.1.1 --release 'p1' --tag 0.8.1.1
```

