
test.prints <- function()
{
    expect_that(print(" , repositories r "), prints_text(GetSQLRepositoriesFrom()))

}

test.commits <- function()
{
    expect_that(1000, equals(EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))))
}

