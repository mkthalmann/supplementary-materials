# "No hard feelings if hard presuppositions project"
# by Maik Thalmann & Andrea Matticchio

library(here)
library(tidyverse)
library(gghalves)
library(patchwork)
library(brms)
library(emmeans)
library(bayestestR)
library(posterior)
library(effectsize)

# hypothesis plot
preds <- tribble(
  ~context,             ~verb,          ~judgment,
  "\u00AC*p* *and*",    "Soft trigger", 1.1,
  "\u00AC*p* *and*",    "Hard trigger", 1.1,
  "Mistaken belief",    "Soft trigger", 6.5,
  "Mistaken belief",    "Hard trigger", 6.5,
  "\u00AC*K*(*p*) *if*", "Soft trigger", 6.1,
  "\u00AC*K*(*p*) *if*", "*too*",       3,
  "\u00AC*K*(*p*) *if*", "*think*",     6.1,
  "\u00AC*K*(*p*) *if*", "Hard trigger", 3,
  "\u00AC*p* *if*",     "Soft trigger", 1.5,
  "\u00AC*p* *if*",     "*too*",       1.5,
  "\u00AC*p* *if*",     "*think*",     5.7,
  "\u00AC*p* *if*",     "Hard trigger", 1.5
)

colors_match <- c(
    "\u00AC*K*(*p*) *if*" = "#066b8a",
    "\u00AC*p* *and*" = "#8a064a",
    "Mistaken belief" = "#d56f09",
    "\u00AC*p* *if*" = "#9109d5"
)

points <- c(
    "\u00AC*K*(*p*) *if*" = 21,
    "\u00AC*p* *and*" = 22,
    "Mistaken belief" = 23,
    "\u00AC*p* *if*" = 24
)
# source(here("scripts", "theme.R"))

p_mistaken <- preds %>%
    mutate(
        verb = fct_relevel(verb, "*too*", "Hard trigger", "Soft trigger"),
        verb = fct_recode(
            verb,
            "Additive" = "*too*",
            "Semi-factive" = "Soft trigger",
            "Emotive factive" = "Hard trigger",
            "Non-factive" = "*think*",
        ),
    ) %>%
    ggplot(aes(
        x = verb,
        y = judgment,
        color = context,
        fill = context,
        shape = context,
        group = context
    )) +
    geom_point(size = 3.5) +
    geom_line() +
    scale_y_continuous(limits = c(1, 7), n.breaks = 6) +
    labs(
        x = "Trigger",
        y = "Judgment",
        color = "Context",
        pch = "Context",
        group = "Context",
        fill = "Context",
        group = "Context",
    ) +
    theme(
        legend.position = "bottom",
        axis.text.y = element_blank(),
        legend.margin = margin(-10, 0, 0, 0, "pt"),
    ) +
    scale_color_manual(values = colors_match) +
    scale_fill_manual(values = colors_match) +
    scale_shape_manual(values = points)

# experimental data for the descriptive plots
d <- read_csv(here("factivity_v2.csv"), show_col_types = FALSE) %>%
    mutate(
        predicate = fct_collapse(predicate, additive = c("again", "too")),
        predicate = gsub("_", " ", predicate),
        predicate = str_to_sentence(predicate),
        predicate = fct_recode(
            predicate,
            "Semi-factive" = "Semi factive",
            "Non-factive" = "Non factive",
            "Emotive factive" = "True factive"
        ),
        predicate = fct_relevel(
            predicate,
            "Additive",
            "Emotive factive",
            "Semi-factive"
        ),
        context = case_when(
            context == "dontknowwhether" ~ "\u00AC*K*(*p*) *if*",
            context == "dontknowwhetherand" ~ "\u00AC*p* *and*",
            context == "mistaken" ~ "Mistaken belief",
            context == "notpif" ~ "\u00AC*p* *if*",
        )
    )

colors <- c(
    "\u00AC*K*(*p*) *if*" = "#066b8a",
    "\u00AC*p* *and*" = "#8a064a",
    "Mistaken belief" = "#d56f09",
    "\u00AC*p* *if*" = "#9109d5"
)

p_a <- d %>%
    filter(
        !(context %in% c("\u00AC*p* *and*", "Mistaken belief"))
    ) %>%
    ggplot(aes(
        x = predicate,
        y = judgment,
        color = context,
        fill = context,
        pch = context
    )) +
    stat_summary(fun = mean, geom = "line", alpha = .5, aes(group = context)) +
    stat_summary(
        fun.data = mean_cl_normal,
        geom = "errorbar",
        width = .1,
        alpha = .7
    ) +
    stat_summary(fun = mean, geom = "point", size = 4) +
    geom_half_violin(
        data = . %>% filter(context != "\u00AC*K*(*p*) *if*"),
        adjust = .7,
        alpha = .2,
        fill = colors[4],
        bw = .4,
        color = "transparent",
        trim = FALSE,
        scale = "count"
    ) +
    geom_half_violin(
        data = . %>% filter(context == "\u00AC*K*(*p*) *if*"),
        adjust = .7,
        alpha = .2,
        fill = colors[1],
        bw = .4,
        color = "transparent",
        trim = FALSE,
        scale = "count",
        side = "R"
    ) +
    scale_y_continuous(limits = c(1, 7), n.breaks = 7, expand = c(.1, 0)) +
    coord_cartesian(clip = "off") +
    labs(
        x = "Trigger",
        y = "Judgment \u00B1 CI<sub>95%</sub>",
        pch = "Context",
        color = "Context",
        fill = "Context"
    ) +
    scale_color_manual(values = colors) +
    scale_fill_manual(values = colors)

p_b <- d %>%
    filter(
        predicate %in% c("Emotive factive", "Semi-factive"),
        context %in% c("\u00AC*p* *and*", "Mistaken belief")
    ) %>%
    ggplot(aes(
        x = predicate,
        y = judgment,
        pch = context,
        color = context,
        fill = context
    )) +
    stat_summary(fun = mean, geom = "line", alpha = .5, aes(group = context)) +
    stat_summary(
        fun.data = mean_cl_normal,
        geom = "errorbar",
        width = .1,
        alpha = .7
    ) +
    stat_summary(fun = mean, geom = "point", size = 4) +
    geom_half_violin(
        data = . %>%
            filter(context != "Mistaken belief"),
        adjust = .7,
        alpha = .2,
        fill = colors[2],
        bw = .4,
        color = "transparent",
        trim = FALSE,
        scale = "count"
    ) +
    geom_half_violin(
        data = . %>%
            filter(context == "Mistaken belief"),
        adjust = .7,
        alpha = .2,
        fill = colors[3],
        bw = .4,
        color = "transparent",
        trim = FALSE,
        scale = "count",
        side = "R"
    ) +
    scale_y_continuous(limits = c(1, 7), n.breaks = 7, expand = c(.1, 0)) +
    coord_cartesian(clip = "off") +
    labs(
        pch = "",
        color = "",
        fill = "",
        y = ""
    ) +
    scale_color_manual(values = colors) +
    scale_fill_manual(values = colors)


p_both <- p_a +
    labs(x = "") +
    theme(legend.margin = margin(-10, 0, 0, 0, "pt")) +
    p_b +
    theme(
        axis.text.y = element_blank(),
        axis.line.y = element_blank(),
        legend.margin = margin(-10, 0, 0, 0, "pt"),
        plot.margin = margin(.05, .05, 0, -1.5, "lines")
    ) +
    plot_layout(guides = "collect", widths = c(2, 1))

ggsave(
    filename = here("factivity-paper.pdf"),
    plot = p_both,
    device = cairo_pdf,
    height = 99,
    width = 220,
    units = "mm"
)
ggsave(
    filename = here("hypothesis-paper.pdf"),
    plot = p_mistaken,
    device = cairo_pdf,
    height = 99,
    width = 220,
    units = "mm"
)


# inferential data
# read in the data again without all of the styling for the plots
d <- read_csv(here("factivity_v2.csv"), show_col_types = FALSE) %>%
    mutate(
        predicate = fct_collapse(predicate, "additive" = c("too", "again")),
        context = as.factor(context)
    )

# data for part a and b
d_part_a <- d %>%
    filter(context %in% c("dontknowwhether", "notpif")) %>%
    mutate(predicate = fct_relevel(predicate, "non_factive"))
d_part_b <- d %>%
    filter(context %in% c("mistaken", "dontknowwhetherand")) %>%
    mutate(predicate = fct_relevel(predicate, "true_factive")) %>%
    mutate(context = fct_relevel(context, "mistaken"))

# models
mod_part_a <- brm(
    judgment ~
        predicate *
            context +
            (1 + predicate * context | payment_code) +
            (1 + context | item_id),
    data = d_part_a,
    family = cumulative("probit"),
    prior = c(
        prior(normal(-1.07, 1), class = Intercept, coef = 1),
        prior(normal(-.566, 1), class = Intercept, coef = 2),
        prior(normal(-.180, 1), class = Intercept, coef = 3),
        prior(normal(.180, 1), class = Intercept, coef = 4),
        prior(normal(.566, 1), class = Intercept, coef = 5),
        prior(normal(1.07, 1), class = Intercept, coef = 6),
        prior(normal(0, 1), class = b)
    ),
    cores = 4,
    iter = 40000,
    file = here("models", "crit_partA"),
    seed = 1234,
    init_r = .2 # otherwise: ERROR 'rejecting starting value'
)

mod_part_b <- update(
    mod_part_a,
    newdata = mod_part_b,
    file = here("models", "crit_partB"),
    cores = 4
)

# model summaries:
diag_summary <- function(model) {
    model %>%
        as_draws_df() %>%
        select(-.chain, -.iteration, -.draw) %>%
        pivot_longer(
            everything(),
            names_to = "parameter",
            values_to = "value"
        ) %>%
        mutate(parameter = fct_inorder(parameter)) %>%
        group_by(parameter) %>%
        summarise(
            rhat = rhat(value),
            assess_Rhat = effectsize::interpret_rhat(rhat),
            ess_bulk = ess_bulk(value),
            assess_ESS = effectsize::interpret_ess(ess_bulk),
            ess_tail = ess_tail(value),
            eti_median = quantile(value, probs = .5),
            eti_2.5 = quantile(value, probs = .025),
            eti_97.5 = quantile(value, probs = .975),
            dens_x = density(value)[1],
            dens_y = density(value)[2],
            dens_z = which.max(unlist(dens_y)),
            hdi_mode = nth(dens_x[[1]], dens_z),
            hdi_95_low = bayestestR::hdi(value)$CI_low,
            hdi_95_high = bayestestR::hdi(value)$CI_high
        ) %>%
        select(-starts_with("dens_")) %>%
        ungroup() %>%
        mutate(across(where(is.numeric), \(x) round(x, digits = 4)))
}
(summary_mod_part_a <- diag_summary(mod_part_a))
(summary_mod_part_b <- diag_summary(mod_part_b))


# bayes factor
# part A
part_a_prior <- bayestestR::unupdate(mod_part_a)
part_a_emmeans <- emmeans::emmeans(
    mod_part_a,
    specs = pairwise ~ predicate * context,
    at = list(predicate = c("semi_factive", "true_factive", "additive"))
)
part_a_emmeans_prior <- emmeans(
    part_a_prior,
    specs = pairwise ~ predicate * context,
    at = list(predicate = c("semi_factive", "true_factive", "additive"))
)
pairwise_part_a <- bayesfactor_parameters(part_a_emmeans, part_a_emmeans_prior)


# same for part B
part_b_prior <- bayestestR::unupdate(mod_part_b)
part_b_emmeans <- emmeans::emmeans(
    mod_part_b,
    specs = pairwise ~ context * predicate
)
part_b_emmeans_prior <- emmeans(
    part_b_prior,
    specs = pairwise ~ context * predicate
)
pairwise_part_b <- bayesfactor_parameters(
    pairs(part_b_emmeans),
    pairs(part_b_emmeans_prior)
)

# bayes factor summaries
pairwise_part_a
pairwise_part_b

# conditional effects plot
cond_effs <- conditional_effects(mod_part_a)[3] %>%
    as.data.frame() %>%
    bind_rows(
        conditional_effects(mod_part_b)[3] %>%
            as.data.frame()
    ) %>%
    select(1, 2, 9, 11, 12)

colnames(cond_effs) <- c("predicate", "context", "estimate", "lower", "upper")

points <- c(
    "\u00AC*K*(*p*) *if*" = 21,
    "\u00AC*p* *and*" = 22,
    "Mistaken belief" = 23,
    "\u00AC*p* *if*" = 24
)
colors_match <- c(
    "\u00AC*K*(*p*) *if*" = "#066b8a",
    "\u00AC*p* *and*" = "#8a064a",
    "Mistaken belief" = "#d56f09",
    "\u00AC*p* *if*" = "#9109d5"
)
p_cond <- cond_effs %>%
    mutate(
        predicate = str_to_sentence(gsub("_", "-", predicate)),
        predicate = gsub("True-factive", "Emotive factive", predicate),
        predicate = fct_relevel(
            predicate,
            "Additive",
            "Emotive factive",
            "Semi-factive",
            "Non-factive"
        ),
        context = case_when(
            context == "dontknowwhether" ~ "\u00AC*K*(*p*) *if*",
            context == "dontknowwhetherand" ~ "\u00AC*p* *and*",
            context == "mistaken" ~ "Mistaken belief",
            context == "notpif" ~ "\u00AC*p* *if*",
        )
    ) %>%
    ggplot(aes(
        x = predicate,
        y = estimate,
        pch = context,
        color = context,
        fill = context,
        group = context
    )) +
    geom_line(alpha = .5) +
    geom_errorbar(
        aes(ymin = lower, ymax = upper),
        width = .05,
        alpha = .7
    ) +
    geom_point(size = 4) +
    labs(
        y = "Posterior conditional means \u00B1HDI<sub>95</sub>",
        x = "Trigger",
        color = "Context",
        fill = "Context",
        pch = "Context",
        group = "Context"
    ) +
    scale_color_manual(values = colors_match) +
    scale_fill_manual(values = colors_match) +
    scale_shape_manual(values = points)

ggsave(
    filename = here("factivity-condmeans-paper.pdf"),
    plot = p_cond + theme(legend.margin = margin(-10, 0, 0, 0, "pt")),
    device = cairo_pdf,
    height = 99,
    width = 210,
    units = "mm"
)
