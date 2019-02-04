Toy in-memory OLAP database in Elixir with ETS backend.

## Features

* Multidimensional cubes
* Hierarchy aggregations by predefined formulas evaluated in parallel
* References for building snowflake schemas
* Formula language with extensible functions
* Extensible data types
* Batch insert with aggregation optimization

## TODO

* MDX queries
* Integration with Excel through ODBO
* Load testing

## Instructions

```bash
mix deps.get
mix compile
mix seeds
iex -S mix
```

To load seeds:

```elixir
Olap.load_seeds(config)
```
