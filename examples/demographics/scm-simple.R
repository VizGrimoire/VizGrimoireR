library("vizgrimoire")

## Analyze command line args, and produce config params from them
#conf <- ConfFromParameters("kdevelop", "jgb", "XXX")
#SetDBChannel (conf$user, conf$password, conf$database)
conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git", group = "fuego")
SetDBChannel (database = conf$database, group = conf$group)

demos <- new ("Demographics")
ages <- GetAges (demos, "2012-10-01")
JSON (ages, "/tmp/ages-2012.json")
Pyramid (ages, "/tmp/ages-2012", 4)
