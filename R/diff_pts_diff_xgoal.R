read_league_from_options_cli <- function(opciones) {
  read_file_from_options_cli(opciones, "league")
}

read_names_from_options_cli <- function(opciones) {
  read_file_from_options_cli(opciones, "names")
}

read_season_from_options_cli <- function(opciones) {
  read_file_from_options_cli(opciones, "season")
}

read_file_from_options_cli <- function(opciones, file) {
  league_season <- opciones[["league-season"]]
  directory <- opciones[["directory"]]
  path <- glue::glue("{directory}/{file}_{league_season}.csv")
  return(read_csv(path, show_col_types = FALSE))
}

get_league_name_from_season <- function(season) {
  return(season$league[1])
}

League <- R6::R6Class("League",
  public = list(
    names = NULL,
    league = NULL,
    team_name = NULL,
    league_name = NULL,
    team = NULL,
    initialize = function(league, season, names) {
      self$names <- names
      self$league <- league %>%
        left_join(season, by = c("match_id" = "id_match"))
      self$league_name <- get_league_name_from_season(season)
    },
    set_id_team = function(id_team) {
      private$id_team <- id_team
      private$set_name()
      point <- extract_point_from_league(self$league, id_team)
      xpoint <- extract_xpoint_from_league(self$league, id_team)
      date <- extract_date_from_league(self$league, id_team)
      xGoal_attacking <- extract_xgoal_attack_from_league(self$league, id_team)
      xGoal_defending <- extract_xgoal_defense_from_league(self$league, id_team)
      match_id <- extract_match_id_from_league(self$league, id_team)
      self$team <- tibble(match_id, date, xpoint, point, xGoal_attacking, xGoal_defending) %>%
        arrange(date)
      private$aggregate_point()
      private$aggregate_point_mean()
      private$aggregate_xpoint()
      private$aggregate_xgoal()
      private$calculate_diff_xgoal()
      private$calculate_diff_points()
    }
  ),
  private = list(
    id_team = NULL,
    set_name = function() {
      self$team_name <- self$names %>%
        filter(ids == private$id_team) %>%
        .$names
    },
    aggregate_point = function() {
      self$team$point_agg <- RcppRoll::roll_sum(self$team$point, n = 4, align = "right", fill = NA)
    },
    aggregate_point_mean = function() {
      self$team$point_mean <- RcppRoll::roll_mean(self$team$point, n = 4, align = "right", fill = NA)
    },
    aggregate_xpoint = function() {
      self$team$xpoint_agg <- RcppRoll::roll_mean(self$team$xpoint, n = 4, align = "right", fill = NA)
    },
    aggregate_xgoal = function() {
      self$team$xGoal_attacking_agg <- RcppRoll::roll_sum(self$team$xGoal_attacking, n = 4, align = "right", fill = NA)
    },
    calculate_diff_xgoal = function() {
      self$team <- self$team %>%
        mutate(diff_xGoal = xGoal_attacking - xGoal_defending)
    },
    calculate_diff_points = function() {
      self$team <- self$team %>%
        mutate(diff_points = point_mean - xpoint_agg)
    }
  )
)
