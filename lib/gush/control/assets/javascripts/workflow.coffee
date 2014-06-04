class @Workflow
  constructor: (@data) ->
    @template = $("#workflow-template").html()
    @view = new View(@template, @templateData(), @partialsData())

  render: ->
    @view.render()

  templateData: ->
    if @data.started_at
      @data.started_at  = moment(@data.started_at  * 1000).format("DD/MM/YYYY HH:mm")
    if @data.finished_at
      @data.finished_at = moment(@data.finished_at * 1000).format("DD/MM/YYYY HH:mm")

    @data

  partialsData: ->
    {progress: @calculateProgress(), status: @data.status, action: @actionData()}

  calculateProgress: ->
    progress = (@data.finished*100) / @data.total;
    @markAsCompleted() if progress == 100

    progress

  updateProgress: ->
    @data.finished += 1
    @view.updateProgress(@calculateProgress())

  changeStatus: (status) ->
    @data.status = status
    @view.updateStatus(status) if @view

  updateDates: (data) ->
    @data.started_at = data.started_at
    @data.finished_at = data.finished_at

    @templateData()
    @view.updateDates(@data) if @view

  markAsCompleted: ->
    @changeStatus("Finished")

  markAsFailed: ->
    @changeStatus("Failed")

  actionData: ->
    {workflow_id: @data.id, status: @data.status};
