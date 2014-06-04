class @Job
  constructor: (@data) ->

  isFinished: ->
    !!@data.finished

  isFailed: ->
    !!@data.failed

  isRunning: ->
    !!@data.running

  isWaiting: ->
    !@isRunning() && !@isFailed()

  status: ->
    switch
      when @isFinished()
        "Finished"
      when @isFailed()
        "Failed"
      when @isRunning()
        "Running"
      else
        "Waiting"

  isValid: ->
    @data.hasOwnProperty("finished")

  render: ->
    Templates.job({name: @data.name, status: @status()} ) if @isValid()
