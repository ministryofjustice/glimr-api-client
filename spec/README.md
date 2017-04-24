# Note on spec organization

`spec/glimr_api_client` specs are mainly integration specs that use
webmock to simulate GLiMR responses.  `spec/lib` are lower-level unit
specs mainly used to target a few mutations that are difficult to kill.

They probably *should* be consolidated, but it isn't a high-priority
task.

