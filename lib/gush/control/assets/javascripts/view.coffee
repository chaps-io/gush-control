class @View
  constructor: (@template, @params, @partialsData) ->

  partials: ->
    {progress: @_progressTemplate(), status: @_statusTemplate(), action: @_actionTemplate() }

  setPartialsData: (@partialsData) ->

  render: ->
    Mustache.render(@template, @params, @partials())

  updateStatus: (status) ->
    @partialsData.status = status

  updateDates: (data) ->
    @params.started_at = data.started_at
    @params.finished_at = data.finished_at

  updateProgress: (progress) ->
    @partialsData.progress = progress

  incrementProgress: ->
    @partialsData.progress += 1

  _progressTemplate: ->
    Templates.progress(@partialsData.progress)

  _statusTemplate: ->
    Templates.status(@partialsData.status)

  _actionTemplate: ->
    Templates.action(@partialsData.action)
