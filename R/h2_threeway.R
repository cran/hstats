#' Three-way Interaction Strength
#' 
#' Friedman and Popescu's statistic of three-way interaction strength, see Details. 
#' Use `plot()` to get a barplot. In `hstats()`, set `threeway_m` to a value above 2
#' to calculate this statistic for all feature triples of the `threeway_m`
#' features with strongest overall interaction.
#' 
#' Friedman and Popescu (2008) describe a test statistic to measure three-way 
#' interactions: in case there are no three-way interactions between features 
#' \eqn{x_j}, \eqn{x_k} and \eqn{x_l}, their (centered) three-dimensional partial 
#' dependence function \eqn{F_{jkl}} can be decomposed into lower order terms:
#' \deqn{
#'   F_{jkl}(x_j, x_k, x_l) = B_{jkl} - C_{jkl}
#' }
#' with
#' \deqn{
#'   B_{jkl} = F_{jk}(x_j, x_k) + F_{jl}(x_j, x_l) + F_{kl}(x_k, x_l)
#' }
#' and
#' \deqn{
#'   C_{jkl} =  F_j(x_j) + F_k(x_k) + F_l(x_l).
#' }
#' 
#' The squared and scaled difference between the two sides of the equation leads to the statistic
#' \deqn{
#'   H_{jkl}^2 = \frac{\frac{1}{n} \sum_{i = 1}^n \big[\hat F_{jkl}(x_{ij}, x_{ik}, x_{il}) - B^{(i)}_{jkl} + C^{(i)}_{jkl}\big]^2}{\frac{1}{n} \sum_{i = 1}^n \hat F_{jkl}(x_{ij}, x_{ik}, x_{il})^2},
#' }
#' where
#' \deqn{
#'   B^{(i)}_{jkl} = \hat F_{jk}(x_{ij}, x_{ik}) + \hat F_{jl}(x_{ij}, x_{il}) + 
#'   \hat F_{kl}(x_{ik}, x_{il})
#' }
#' and
#' \deqn{
#'   C^{(i)}_{jkl} = \hat F_j(x_{ij}) + \hat F_k(x_{ik}) + \hat F_l(x_{il}).
#' }
#' Similar remarks as for [h2_pairwise()] apply.
#' 
#' @inheritParams h2_overall
#' @inherit h2_overall return
#' @inherit hstats references
#' @export
#' @seealso [hstats()], [h2()], [h2_overall()], [h2_pairwise()]
#' @examples
#' # MODEL 1: Linear regression
#' fit <- lm(uptake ~ Type * Treatment * conc, data = CO2)
#' s <- hstats(fit, X = CO2[, 2:4], threeway_m = 5)
#' h2_threeway(s)
#' 
#' #' MODEL 2: Multivariate output (taking just twice the same response as example)
#' fit <- lm(cbind(up = uptake, up2 = 2 * uptake) ~ Type * Treatment * conc, data = CO2)
#' s <- hstats(fit, X = CO2[, 2:4], threeway_m = 5)
#' h2_threeway(s)
#' h2_threeway(s, normalize = FALSE, squared = FALSE)  # Unnormalized H
#' plot(h2_threeway(s))
h2_threeway <- function(object, ...) {
  UseMethod("h2_threeway")
}

#' @describeIn h2_threeway Default pairwise interaction strength.
#' @export
h2_threeway.default <- function(object, ...) {
  stop("No default method implemented.")
}

#' @describeIn h2_threeway Pairwise interaction strength from "hstats" object.
#' @export
h2_threeway.hstats <- function(
    object, normalize = TRUE, squared = TRUE, sort = TRUE, zero = TRUE, ...
  ) {
  get_hstats_matrix(
    statistic = "h2_threeway",
    object = object,
    normalize = normalize,
    squared = squared,
    sort = sort,
    zero = zero
  )
}

#' Raw H2 Threeway
#' 
#' Internal helper function that calculates numerator and denominator of
#' statistic in title.
#' 
#' @noRd
#' @keywords internal
#' @param x A list containing the elements "combs3", "v_threeway_0", "K", "pred_names", 
#'   "F_jkl", "F_jk", "F_j", "eps", and "w".
#' @returns A list with the numerator and denominator statistics.
h2_threeway_raw <- function(x) {
  num <- init_numerator(x, way = 3L)
  denom <- num + 1
  
  # Note that the F_jkl are in the same order as x[["combs3"]]
  combs <- x[["combs3"]]
  if (!is.null(combs)) {
    for (nm in names(combs)) {
      z <- combs[[nm]]
      zz <- utils::combn(z, 2L, paste, collapse = ":")
      
      num[nm, ] <- with(
        x, 
        wcolMeans((F_jkl[[nm]] - Reduce("+", F_jk[zz]) + Reduce("+", F_j[z]))^2, w = w)
      )
      denom[nm, ] <- with(x, wcolMeans(F_jkl[[nm]]^2, w = w))
    }    
  }
  num <- .zap_small(num, eps = x[["eps"]])  # Numeric precision

  list(num = num, denom = denom)
}

