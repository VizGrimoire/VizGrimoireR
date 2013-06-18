
test.prints <- function()
{
    expect_that(print(" , repositories r "), prints_text(GetSQLRepositoriesFrom()))

}


