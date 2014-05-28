(function(){
  var root = this,
      self, statusSocket;

  var Gush = {

    initialize: function(){
      self = this;
      console.log("Hello from gush");
      this.registerSockets();
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
        case "finished":
          self.onJobSuccess(message);
        case "heartbeat":
          self.onJobHeartbeat(message);
        case "failed":
          self.onJobFail(message);
      }
    },

    onJobStart: function(message){
      console.log("Job started:", message.job);
    },

    onJobSuccess: function(message){
      console.log("Job success:");
      console.log(message);
    },

    onJobHeartbeat: function(message){
    },

    onJobFail: function(message){
      console.log("Job failed:");
      console.log(message);
    }
  };

  root.Gush = Gush;
})();


Gush.initialize();
