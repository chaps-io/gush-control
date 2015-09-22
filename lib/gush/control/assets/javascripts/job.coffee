class @Job
  constructor: (@data) ->

  isFinished: ->
    !!@data.finished

  isFailed: ->
    !!@data.failed

  isRunning: ->
    !!@data.running

  isWaiting: ->
    !@isEnqueued() && !@isRunning() && !@isFailed()

  isEnqueued: ->
    !!@data.enqueued

  status: ->
    switch
      when @isFinished()
        "Finished"
      when @isFailed()
        "Failed"
      when @isEnqueued()
        "Enqueued"
      when @isRunning()
        "Running"
      else
        "Waiting"

  isValid: ->
    @data.hasOwnProperty("finished")

  render: ->
    if @isValid()
      Templates.job
        name: @data.name
        started_at: @data.started_at
        finished_at: @data.finished_at
        status: @status()
        class: @status().toLowerCase()

