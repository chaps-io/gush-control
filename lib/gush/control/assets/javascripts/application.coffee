window.Gush = new Gush
$(document).ready ->
  window.Gush.initialize()
  Foundation.global.namespace = ''
  $(document).foundation()

  $(this).on "click", ".button.start-workflow", (event) ->
    if !$(event.target).is(".button")
      return
    if($(this).data("action") == "start")
      Gush.startWorkflow($(this).data("workflow-id"), $(this))
    else
      Gush.stopWorkflow($(this).data("workflow-id"), $(this))

  $(this).on "click", ".start-job", (event) ->
    Gush.startJob($(this).data("workflow-id"), $(this).data("job-name"), $(this))

  $(this).on "click", ".create-workflow", ->
    Gush.createWorkflow($(this).data("workflow-class"))

  $(this).on "click", ".destroy-workflow", ->
    Gush.destroyWorkflow($(this).data("workflow-id"), $(this))

  $(this).on "dblclick", "svg .node", ->
    workflow_id = $(this).closest('svg').data('workflow-id')
    name = $(this).data('job-name')
    window.location.href = "/jobs/#{workflow_id}.#{name}"
