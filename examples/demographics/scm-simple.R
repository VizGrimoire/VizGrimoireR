library("vizgrimoire")

## Analyze command line args, and produce config params from them
#conf <- ConfFromParameters("kdevelop", "jgb", "XXX")
conf <- ConfFromParameters(dbschema = "acs_cvsanaly_allura", group = "fuego")
#SetDBChannel (conf$user, conf$password, conf$database)
SetDBChannel (database = conf$database, group = conf$group)

demos <- new ("Demographics")

Pyramid (demos, "2010-01-01", "/tmp/demos-pyramid-2010")
JSON (demos, "/tmp/demos-pyramid-2010.json")
Pyramid (demos, "2012-01-01", "/tmp/demos-pyramid-2012")
JSON (demos, "/tmp/demos-pyramid-2012.json")
