#' Overall Interaction Strength
#' 
#' Friedman and Popescu's statistic of overall interaction strength per 
#' feature, see Details. 
#' By default, the results are plotted as barplot. Set `plot = FALSE` to get numbers.
#' 
#' @details
#' The logic of Friedman and Popescu (2008) is as follows: 
#' If there are no interactions involving feature \eqn{x_j}, we can decompose the 
#' (centered) prediction function \eqn{F} into the sum of the (centered) partial 
#' dependence \eqn{F_j} on \eqn{x_j} and the (centered) partial dependence 
#' \eqn{F_{\setminus j}} on all other features \eqn{\mathbf{x}_{\setminus j}}, i.e.,
#' \deqn{
#'   F(\mathbf{x}) = F_j(x_j) + F_{\setminus j}(\mathbf{x}_{\setminus j}).
#' }
#' Correspondingly, Friedman and Popescu's statistic of overall interaction 
#' strength is given by
#' \deqn{
#'   H_j^2 = \frac{\frac{1}{n} \sum_{i = 1}^n\big[F(\mathbf{x}_i) - 
#'   \hat F_j(x_{ij}) - \hat F_{\setminus j}(\mathbf{x}_{i\setminus j})
#'   \big]^2}{\frac{1}{n} \sum_{i = 1}^n\big[F(\mathbf{x}_i)\big]^2}
#' }
#' (check [partial_dep()] for all definitions).
#' 
#' **Remarks:**
#' 
#' 1. Partial dependence functions (and \eqn{F}) are all centered to 
#'   (possibly weighted) mean 0.
#' 2. Partial dependence functions (and \eqn{F}) are evaluated over the data distribution. 
#'   This is different to partial dependence plots, where one uses a fixed grid.
#' 3. Weighted versions follow by replacing all arithmetic means by corresponding
#'   weighted means.
#' 4. Multivariate predictions can be treated in a component-wise manner.
#' 5. Due to (typically undesired) extrapolation effects of partial dependence functions, 
#'   depending on the model, values above 1 may occur.
#' 6. \eqn{H^2_j = 0} means there are no interactions associated with \eqn{x_j}. 
#'   The higher the value, the more prediction variability comes from interactions 
#'   with \eqn{x_j}.
#' 7. Since the denominator is the same for all features, the values of the test 
#'   statistics can be compared across features.
#' 
#' @param object Object of class "hstats".
#' @param normalize Should statistic be normalized? Default is `TRUE`.
#' @param squared Should *squared* statistics be returned? Default is `TRUE`. 
#' @param sort Should results be sorted by the size of the statistic? Default is `TRUE`.
#'   Multioutput predictions are sorted by row means.
#' @param top_m How many statistics should be shown? By default `15`. 
#'   Set to `Inf` to show all.
#' @param eps Threshold below which numerator values are set to 0.
#' @param plot Should results be plotted as barplot? Default is `FALSE`.
#' @param fill Color of bar (only for univariate statistics).
#' @param ... Further parameters passed to `geom_bar()`.
#' @returns 
#'   A matrix of statistics (one row per variable, one column per prediction dimension),
#'   or a "ggplot" object (if `plot = TRUE`).
#' @inherit hstats references
#' @seealso [hstats()], [h2()], [h2_pairwise()], [h2_threeway()]
#' @export
#' @examples
#' # MODEL 1: Linear regression
#' fit <- lm(Sepal.Length ~ . + Petal.Width:Species, data = iris)
#' s <- hstats(fit, v = names(iris[-1]), X = iris, verbose = FALSE)
#' h2_overall(s, plot = TRUE)
#' 
#' # MODEL 2: Multi-response linear regression
#' fit <- lm(as.matrix(iris[1:2]) ~ Petal.Length + Petal.Width * Species, data = iris)
#' v <- c("Petal.Length", "Petal.Width", "Species")
#' s <- hstats(fit, v = v, X = iris, verbose = FALSE)
#' h2_overall(s, plot = TRUE)
h2_overall <- function(object, ...) {
  UseMethod("h2_overall")
}

#' @describeIn h2_overall Default method of overall interaction strength.
#' @export
h2_overall.default <- function(object, ...) {
  stop("No default method implemented.")
}

#' @describeIn h2_overall Overall interaction strength from "hstats" object.
#' @export
h2_overall.hstats <- function(object, normalize = TRUE, squared = TRUE, sort = TRUE, 
                              top_m = 15L, eps = 1e-8, plot = TRUE, fill = "#2b51a1", 
                              ...) {
  num <- with(
    object, matrix(nrow = length(v), ncol = K, dimnames = list(v, pred_names))
  )
  for (z in object[["v"]]) {
    num[z, ] <- with(object, wcolMeans((f - F_j[[z]] - F_not_j[[z]])^2, w = w))
  }
  out <- postprocess(
    num = num,
    denom = object[["mean_f2"]],
    normalize = normalize, 
    squared = squared, 
    sort = sort, 
    top_m = top_m, 
    eps = eps
  )
  if (plot) plot_stat(out, fill = fill, ...) else out
}