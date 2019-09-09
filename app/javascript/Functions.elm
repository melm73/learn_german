module Functions exposing (fullWord)


fullWord : Maybe String -> String -> String
fullWord maybeArticle word =
    case maybeArticle of
        Nothing ->
            word

        Just article ->
            article ++ " " ++ word
