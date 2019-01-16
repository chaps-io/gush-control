window.Gush = new Gush

$(document).ready ->
  jobs = $('#jobs').data('list') || []
  window.Gush.initialize(jobs)
  Foundation.global.namespace = ''
  $(document).foundation()

  $(this).on "click", ".button.start-workflow", (event) ->
    event.preventDefault()
    if !$(event.target).is(".button")
      return
    if($(this).data("action") == "start")
      Gush.startWorkflow($(this).data("workflow-id"), $(this))
    else
      Gush.stopWorkflow($(this).data("workflow-id"), $(this))

  $(this).on "click", ".start-job", (event) ->
    event.preventDefault()
    Gush.startJob($(this).data("workflow-id"), $(this).data("job-name"), $(this))

  $(this).on "click", ".create-workflow", (event) ->
    event.preventDefault()
    Gush.createWorkflow($(this).data("workflow-class"))

  $(this).on "click", ".destroy-workflow", (event) ->
    event.preventDefault()
    Gush.destroyWorkflow($(this).data("workflow-id"), $(this))

  $(this).on "click", ".retry-workflow", (event) ->
    event.preventDefault()
    Gush.retryWorkflow($(this).data("workflow-id"), $(this))

  $(this).on "dblclick", "svg .node", (event) ->
    event.preventDefault()
    workflow_id = $(this).closest('svg').data('workflow-id')
    name = $(this).data('job-name')
    if name isnt "Start" and name isnt "End"
      window.location.href = "#{Gush.appPrefix}/jobs/#{workflow_id}.#{name}"

  $(this).on "click", ".jobs-filter dd a", (event) ->
    event.preventDefault()
    filter = $(this).data('filter')
    $(this).closest('dl').find('dd').removeClass('active')
    $(this).parent().addClass('active')
    Gush.filterJobs(filter)


  $(this).on "click", "a.remove-completed", (event) ->
    event.preventDefault()
    Gush.removeCompleted()

  $(this).on "click", "a.remove-logs", (event) ->
    event.preventDefault()
    Gush.removeLogs($(this).data('workflow-id'), $(this).data('job-name'))
