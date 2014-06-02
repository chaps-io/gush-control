

(function(){
  var root = this,
      self, statusSocket, workflows;

  var Gush = {

    initialize: function(){
      self = this;
      workflows = [];
      $('table.workflows').data('workflows').forEach(function (data) {
        self.addWorkflow(data);
      });
      console.log("Hello from gush");
      this.registerSockets();
    },

    getWorkflows: function(){
      return workflows;
    },

    registerSockets: function(){
      this.registerStatusSocket();
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
      console.log("Job started:", message.job);
    },

    onJobSuccess: function(message){
      var workflow = workflows[message.workflow_id];
      workflow.updateProgress();
      $("table.workflows").find("#" + message.workflow_id).replaceWith(workflow.render());
    },

    onJobHeartbeat: function(message){
    },

    onJobFail: function(message){
      var workflow = workflows[message.workflow_id];
      workflow.markAsFailed();
      $("table.workflows").find("#" + message.workflow_id).replaceWith(workflow.render());
    },

    startWorkflow: function(workflow){
      $.ajax({
        url: "/run/" + workflow,
        type: "POST",
        error: function(response){
          console.log(response);
        },
        success: function(response){
          self.addWorkflow(response);
        }
      });
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
      this.view.updateStatus("Finished");
    },
    this.markAsFailed = function(){
      this.view.updateStatus("Failed");
    },
    this.calculateProgress = function(){
      var progress = (this.data.finished*100)/this.data.total;
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
      if(progress == 100){
        this.markAsCompleted();
      }
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


$(document).ready(function () {
  Gush.initialize();
});
