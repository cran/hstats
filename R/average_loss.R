#' Average Loss
#'
#' Calculates the average loss of a model on a given dataset, 
#' optionally grouped by a variable. Use `plot()` to visualize the results.
#' 
#' @section Losses: 
#' 
#' The default `loss` is the "squared_error". Other choices: 
#' - "absolute_error": The absolute error is the loss corresponding to median regression. 
#' - "poisson": Unit Poisson deviance, i.e., the loss function used in 
#'   Poisson regression. Actual values `y` and predictions must be non-negative.
#' - "gamma": Unit gamma deviance, i.e., the loss function of Gamma regression.
#'   Actual values `y` and predictions must be positive.
#' - "logloss": The Log Loss is the loss function used in logistic regression,
#'   and the top choice in probabilistic binary classification. Responses `y` and
#'   predictions must be between 0 and 1. Predictions represent probabilities of 
#'   having a "1".
#' - "mlogloss": Multi-Log-Loss is the natural loss function in probabilistic multi-class 
#'   situations. If there are K classes and n observations, the predictions form
#'   a (n x K) matrix of probabilities (with row-sums 1).
#'   The observed values `y` are either passed as (n x K) dummy matrix, 
#'   or as discrete vector with corresponding levels. 
#'   The latter case is turned into a dummy matrix by a fast version of
#'   `model.matrix(~ as.factor(y) + 0)`.
#' - A function with signature `f(actual, predicted)`, returning a numeric 
#'   vector or matrix of the same length as the input.
#'
#' @inheritParams hstats
#' @param y Vector/matrix of the response, or the corresponding column names in `X`.
#' @param loss One of "squared_error", "logloss", "mlogloss", "poisson",
#'   "gamma", or "absolute_error". Alternatively, a loss function 
#'   can be provided that turns observed and predicted values into a numeric vector or 
#'   matrix of unit losses of the same length as `X`.
#'   For "mlogloss", the response `y` can either be a dummy matrix or a discrete vector. 
#'   The latter case is handled via a fast version of `model.matrix(~ as.factor(y) + 0)`.
#'   For "squared_error", the response can be a factor with levels in column order of
#'   the predictions. In this case, squared error is evaluated for each one-hot-encoded column.
#' @param agg_cols Should multivariate losses be summed up? Default is `FALSE`.
#'   In combination with the squared error loss, `agg_cols = TRUE` gives
#'   the Brier score for (probabilistic) classification.
#' @param BY Optional grouping vector or column name.
#'   Numeric `BY` variables with more than `by_size` disjoint values will be 
#'   binned into `by_size` quantile groups of similar size. 
#' @param by_size Numeric `BY` variables with more than `by_size` unique values will
#'   be binned into quantile groups. Only relevant if `BY` is not `NULL`.
#' @inherit h2_overall return
#' @export
#' @examples
#' # MODEL 1: Linear regression
#' fit <- lm(Sepal.Length ~ ., data = iris)
#' average_loss(fit, X = iris, y = "Sepal.Length")
#' average_loss(fit, X = iris, y = iris$Sepal.Length, BY = iris$Sepal.Width)
#' average_loss(fit, X = iris, y = "Sepal.Length", BY = "Sepal.Width")
#'
#' # MODEL 2: Multi-response linear regression
#' fit <- lm(as.matrix(iris[, 1:2]) ~ Petal.Length + Petal.Width + Species, data = iris)
#' average_loss(fit, X = iris, y = iris[, 1:2])
#' L <- average_loss(
#'   fit, X = iris, y = iris[, 1:2], loss = "gamma", BY = "Species"
#' )
#' L
#' plot(L)
average_loss <- function(object, ...) {
  UseMethod("average_loss")
}

#' @describeIn average_loss Default method.
#' @export
average_loss.default <- function(
    object,
    X,
    y,
    pred_fun = stats::predict,
    loss = "squared_error",
    agg_cols = FALSE,
    BY = NULL,
    by_size = 4L,
    w = NULL,
    ...
  ) {
  stopifnot(
    is.matrix(X) || is.data.frame(X),
    is.function(pred_fun)
  )
  y <- prepare_y(y = y, X = X)[["y"]]
  if (!is.null(w)) {
    w <- prepare_w(w = w, X = X)[["w"]]
  }
  if (!is.null(BY)) {
    BY <- prepare_by(BY = BY, X = X, by_size = by_size)[["BY"]]
  }
  if (!is.function(loss)) {
    loss <- get_loss_fun(loss)
  }
  
  # Real work
  pred <- prepare_pred(pred_fun(object, X, ...))
  M <- gwColMeans(loss(y, pred), g = BY, w = w)[["M"]]
  
  if (agg_cols && ncol(M) > 1L) {
    M <- cbind(rowSums(M))
  }
  
  structure(
    list(
      M = M, 
      SE = NULL, 
      mrep = NULL, 
      statistic = "average_loss", 
      description = "Average loss"
    ), 
    class = "hstats_matrix"
  )
}

#' @describeIn average_loss Method for "ranger" models.
#' @export
average_loss.ranger <- function(
    object,
    X,
    y,
    pred_fun = function(m, X, ...)
    stats::predict(m, X, ...)$predictions,
    loss = "squared_error",
    agg_cols = FALSE,
    BY = NULL, by_size = 4L,
    w = NULL,
    ...
  ) {
  average_loss.default(
    object = object, 
    X = X, 
    y = y, 
    pred_fun = pred_fun,
    loss = loss, 
    agg_cols = agg_cols,
    BY = BY,
    by_size = by_size,
    w = w, 
    ...
  )
}

#' @describeIn average_loss Method for DALEX "explainer".
#' @export
average_loss.explainer <- function(
    object, 
    X = object[["data"]],
    y = object[["y"]],
    pred_fun = object[["predict_function"]],
    loss = "squared_error",
    agg_cols = FALSE,
    BY = NULL,
    by_size = 4L,
    w = object[["weights"]],
    ...
  ) {
  average_loss.default(
    object = object[["model"]],
    X = X,
    y = y,
    pred_fun = pred_fun,
    loss = loss,
    agg_cols = agg_cols,
    BY = BY,
    by_size = by_size,
    w = w,
    ...
  )
}

