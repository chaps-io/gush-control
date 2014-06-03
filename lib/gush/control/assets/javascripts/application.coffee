window.Gush = new Gush
$(document).ready ->
  window.Gush.initialize()
  Foundation.global.namespace = ''
  $(document).foundation()

  $(this).on "click", ".button.start-workflow", ->
    if($(this).data("action") == "start")
      Gush.startWorkflow($(this).data("workflow-id"), $(this))
    else
      Gush.stopWorkflow($(this).data("workflow-id"), $(this))

  $(this).on "click", ".create-workflow", ->
    Gush.createWorkflow($(this).data("workflow-class"))
