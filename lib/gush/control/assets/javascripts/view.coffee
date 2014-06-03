class @View
  constructor: (@template, @params, @partialsData) ->

  partials: ->
    {progress: @_progressTemplate(), status: @_statusTemplate(), action: @_actionTemplate() }

  render: ->
    Mustache.render(@template, @params, @partials())

  updateStatus: (status) ->
    this.partialsData.status = status;

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
