(function(){
  var root = this,
      self, statusSocket, workflows;

  var Gush = {

    initialize: function(){
      self = this;
      workflows = [];
      console.log("Hello from gush");
      this.registerSockets();
      this.displayCurrentWorkflows();
    },

    getWorkflows: function(){
      return workflows;
    },

    registerSockets: function(){
      this.registerStatusSocket();
    },

    displayCurrentWorkflows: function(){
      $("table.workflows tbody").empty();
      $.each(($("table.workflows").data("workflows") || []), function(){
        self.addWorkflow(this);
      });
    },

    registerStatusSocket: function(){
      statusSocket = new EventSource("/subscribe/workers.status");

      statusSocket.onopen    = this.onOpen;
      statusSocket.onerror   = this.onError;
      statusSocket.onmessage = this.onStatus;
      statusSocket.onclose   = this.onClose;
    },

    onOpen: function(){
      console.log("Socket has been opened!");
    },

    onError: function(error){
      console.log(error);
    },

    onClose: function(){
      console.log("Connection closed");
    },

    onStatus: function(message){
      message = JSON.parse(message.data);

      switch(message.status){
        case "started":
          self.onJobStart(message);
          break;
        case "finished":
          self.onJobSuccess(message);
          break;
        case "heartbeat":
          self.onJobHeartbeat(message);
          break;
        case "failed":
          self.onJobFail(message);
          break;
        default:
          console.error("Unkown job status:", message.status, "data: ", message);
      }
    },

    onJobStart: function(message){
      this.markGraphNode(message.workflow_id, message.job, 'status-running');
      console.log("Job started:", message.job);
    },

    onJobSuccess: function(message){
      this.markGraphNode(message.workflow_id, message.job, 'status-finished');

      var workflow = workflows[message.workflow_id];
      if (workflow) {
        workflow.updateProgress();
        $("table.workflows").find("#" + message.workflow_id).replaceWith(workflow.render());
      }
    },

    onJobHeartbeat: function(message){
    },

    onJobFail: function(message){
      this.markGraphNode(message.workflow_id, message.job, 'status-finished status-failed');

      var workflow = workflows[message.workflow_id];
      workflow.markAsFailed();
      $("table.workflows").find("#" + message.workflow_id).replaceWith(workflow.render());
    },

    startWorkflow: function(workflow, el){
      $.ajax({
        url: "/start/" + workflow,
        type: "POST",
        error: function(response){
          console.log(response);
        }
      });

      if(el){
        el.removeClass("success")
          .addClass("alert")
          .data("action", "stop")
          .text("Stop Workflow")
      }
    },

    stopWorkflow: function(workflow, el){
      if(el){
        el.addClass("success")
          .removeClass("alert")
          .data("action", "start")
          .text("Start Workflow")
      }
    },

    createWorkflow: function(workflow){
      $.ajax({
        url: "/create/" + workflow,
        type: "POST",
        error: function(response){
          console.log(response);
        },
        success: function(response){
          self.addWorkflow(response);
        }
      });
    },

    markGraphNode: function(workflow_id, name, class_names) {
      name = name.replace(/::/g, '_').toLowerCase();
      $('svg[data-workflow-id=' + workflow_id +'] .node.' + name)
        .attr('class', 'node ' + name + ' ' + class_names);

      var total = $('svg[data-workflow-id=' + workflow_id +'] .node').length;
      var finished = $('svg[data-workflow-id=' + workflow_id +'] .node.status-finished').length;

      if (finished == total) {
        $('.button.start-workflow')
          .addClass('success')
          .removeClass('alert')
          .text("Start workflow");
      }
    },

    addWorkflow: function(data){
      data.progress = 0;
      var workflow = new Workflow(data);
      workflows[data.id] = workflow;

      $("table.workflows").append(workflow.render());
    }
  };

  var Workflow = function(data){
    this.data = data;
    this.template = $("#workflow-template").html();
    this.render = function(){
      return this.view.render();
    };
    this.updateProgress = function(){
      this.data.finished += 1;
      this.view.updateProgress(this.calculateProgress());
      return true;
    },
    this.markAsCompleted = function(){
      this.data.status = "Finished";
      if(this.view){
        this.view.updateStatus("Finished");
      }
    },
    this.markAsFailed = function(){
      this.data.status = "Failed";
      if(this.view){
        this.view.updateStatus("Failed");
      }
    },
    this.calculateProgress = function(){
      var progress = (this.data.finished*100)/this.data.total;
      if(progress == 100){
        this.markAsCompleted();
      }
      return progress;
    },
    this.view = new View(this.template, data, {progress: this.calculateProgress(), status: data.status});
  };

  var Templates = {
    status: function(status){
      var labelClass = {"Failed": "alert", "Running": "", "Finished": "success", "Pending": "secondary"};
      var template = $("#status-template").html();
      return Mustache.render(template, {status: status, class: labelClass[status]});
    },

    progress: function(progress){
      var template = $("#progress-template").html();
      return Mustache.render(template, {progress: parseInt(progress)});
    }
  };

  var View = function(template, params, partialsData){
    this.template = template;
    this.params = params;
    this.partialsData = partialsData;
    this.updateStatus = function(status){
      this.partialsData.status = status;
    },
    this.updateProgress = function(progress){
      this.partialsData.progress = progress;
    },
    this.incrementProgress = function(){
      this.partialsData.progress += 1;
    },
    this.partials = function(){
      return {progress: Templates.progress(this.partialsData.progress), status: Templates.status(this.partialsData.status)};
    },
    this.render = function(){
      return Mustache.render(template, params, this.partials());
    };
  };

  root.Gush = Gush;
})();

$(document).ready(function(){
  Gush.initialize();

  $(this).on("click", ".button.start-workflow", function(){
    if($(this).data("action") === "start"){
      Gush.startWorkflow($(this).data("workflow-id"), $(this));
    }
    else{
    Gush.stopWorkflow($(this).data("workflow-id"), $(this));
    }
  });
});
