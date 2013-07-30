  window.addEvent('domready', () ->

  Workspace = Backbone.Router.extend({
    routes: {
      'profile/new': 'profile',
      'profile/:id': 'profile'
    },

    profile: (id) ->
      console.log('foo')
      console.log(id)
  });
  Application = new Workspace()

  Backbone.history.start({pushState: true})

  #
  # Instantiate everything
  #
  hostsContainer = $('hosts')
  hosts     = new HostCollection
  hostsView = new DimensionCollectionView({
    collection: hosts,
    container: hostsContainer
  })
  hosts.fetch({
    success: (collection) ->
      list = hostsView.render().el
      hostsContainer.grab(list)
  })

  metricsContainer = $('metrics')
  metrics     = new MetricCollection
  metricsView = new DimensionCollectionView({
    collection: metrics,
    container:  metricsContainer
  })
  metrics.fetch({
    success: (collection) ->
      list = metricsView.render().el
      metricsContainer.grab(list)
  })

  graphsContainer = $('graphs')
  graphs          = new GraphCollection
  graphsView      = new GraphCollectionView({
    el:         graphsContainer
    collection: graphs
  })

  # If we're working with an existing profile, fetch the details and render
  # the graphs
  if document.location.pathname.split('/')[2] != 'new'
    profile = new Profile()
    profile.fetch({
      success: (model) ->
        model.get('graphs').each((attributes) ->
          graph = new Graph(attributes)
          graph.fetch({
            success: (model, response) ->
              graphs.add(graph)
              graphsView.render().el
          })
        )
    })

  button = new Element('input', {
    'type': 'button',
    'value': 'Show graphs',
    'class': 'button',
    'styles': {
      'font-size': '80%',
      'padding': '4px 8px',
    },
    'events': {
      'click': (event) ->
        selected_hosts   = hosts.selected().map((host) -> host.get('id')).unique()
        selected_metrics = metrics.selected().map((metric) -> metric.get('id').split('/')[0]).unique()

        selected_hosts.each((host) ->
          selected_metrics.each((metric) ->

            attributes = {
              host:   host
              plugin: metric
            }
            timeframe  = JSON.decode(Cookie.read('timeframe'))
            attributes = Object.merge(attributes, timeframe)

            graph = new Graph(attributes)
            graph.fetch({
              success: (model, response, options) ->
                graphs.add(graph)
                graphsView.render().el
              error: (model, response, options) ->
                console.log('error', model, response, options)
            })
          )

          builder = $('builder')
          builder.tween('padding-top', 24).get('tween').chain(() ->
            builder.setStyle('border-top', '1px dotted #aaa')
          )


        )
    }
  })
  $('display').grab(button)


  timeframes = new TimeframeCollection
  timeframes.add([
    { label: 'last 1 hour',      start: -1,     unit: 'hours' }
    { label: 'last 2 hours',     start: -2,     unit: 'hours' }
    { label: 'last 6 hours',     start: -6,     unit: 'hours' }
    { label: 'last 12 hours',    start: -12,    unit: 'hours' }
    { label: 'last 24 hours',    start: -24,    unit: 'hours' }
    { label: 'last 3 days',      start: -72,    unit: 'hours' }
    { label: 'last 7 days',      start: -168,   unit: 'hours' }
    { label: 'last 2 weeks',     start: -336,   unit: 'hours' }
    { label: 'last 1 month',     start: -774,   unit: 'hours' }
    { label: 'last 3 months',    start: -2322,  unit: 'hours' }
    { label: 'last 6 months',    start: -4368,  unit: 'hours' }
    { label: 'last 1 year',      start: -8760,  unit: 'hours' }
    { label: 'last 2 years',     start: -17520, unit: 'hours' }
    { label: 'current month',    start: 0,  finish: 1,  unit: 'months' }
    { label: 'previous month',   start: -1, finish: 0,  unit: 'months' }
    { label: 'two months ago',   start: -2, finish: -1, unit: 'months' }
    { label: 'three months ago', start: -3, finish: -2, unit: 'months' }
  ])

  if profile
    timeframes.add({
      label:   'As specified by profile',
      default: true
    }, {at: 0})

  timeframesView = new TimeframeCollectionView({
    collection: timeframes,
    el:         $('timeframes')
  })
  timeframesView.render()
  )