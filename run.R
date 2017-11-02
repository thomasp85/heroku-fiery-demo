library(fiery)
library(routr)

set.seed(1492)
x <- rnorm(15)
y <- x + rnorm(15)
fit <- lm(y ~ x)
saveRDS(fit, "model.rds")

app <- Fire$new(host = '0.0.0.0', port = as.integer(Sys.getenv('PORT')))
app$set_logger(logger_console())

# When the app starts, we'll load the model we saved. Instead of
# polluting our namespace we'll use the internal data store

app$on('start', function(server, ...) {
  server$set_data('model', readRDS('model.rds'))
  message('Model loaded')
})

# Just for show off, we'll make it so that the model is automatically
# passed on to the request handlers

app$on('before-request', function(server, ...) {
  list(model = server$get_data('model'))
})

# Now comes the biggest deviation. We'll use routr to define our request
# logic, as this is much nicer
router <- RouteStack$new()
route <- Route$new()
router$add_route(route, 'main')

# We start with a catch-all route that provides a welcoming html page
route$add_handler('get', '*', function(request, response, keys, ...) {
  response$type <- 'html'
  response$status <- 200L
  response$body <- '<h1>All your AI are belong to us</h1>'
  TRUE
})
# Then on to the /info route
route$add_handler('get', '/info', function(request, response, keys, ...) {
  response$status <- 200L
  response$body <- structure(R.Version(), class = 'list')
  response$format(json = reqres::format_json())
  TRUE
})
# Lastly we add the /predict route
route$add_handler('get', '/predict', function(request, response, keys, arg_list, ...) {
  response$body <- predict(
    arg_list$model, 
    data.frame(x=as.numeric(request$query$val)),
    se.fit = TRUE
  )
  response$status <- 200L
  response$format(json = reqres::format_json())
  TRUE
})
# And just to show off reqres file handling, we'll add a route 
# for getting a model plot
route$add_handler('get', '/plot', function(request, response, keys, arg_list, ...) {
  f_path <- tempfile(fileext = '.png')
  png(f_path)
  plot(arg_list$model)
  dev.off()
  response$status <- 200L
  response$attach(f_path, filename = 'model_plot.png')
  TRUE
})

# Finally we attach the router to the fiery server
app$attach(router)

app$ignite()
