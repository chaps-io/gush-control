class @Templates
  @status: (status) ->
    labelClass = {"Failed": "alert", "Running": "", "Finished": "success", "Pending": "secondary"}
    template = $("#status-template").html()
    Mustache.render(template, {status: status, class: labelClass[status]})

  @progress: (progress) ->
    template = $("#progress-template").html();
    Mustache.render(template, {progress: parseInt(progress)});

  @job: (data) ->
    template = $("#node-template").html()
    Mustache.render(template, data)

  @machine: (data) ->
    template = $("#machine-template").html()
    Mustache.render(template, data)

  @action: (data) ->
    description = if data.status == "Running" then "Stop Workflow" else "Start workflow"
    buttonClass = {"Start workflow": "success", "Stop Workflow": "alert"}
    buttonAction = if data.status == "Running" then "stop" else "start"
    template = $("#workflow-action-template").html()

    if data.status != "Finished"
      Mustache.render(template, {workflow_id: data.workflow_id, action: buttonAction, classes: buttonClass[description], description: description})
