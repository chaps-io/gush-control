(function(){
  var root = this,
    statusSocket;

  var Gush = {
    initialize: function(){
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

    onStatus: function(message){;
      message = JSON.parse(message.data);
      console.log(message);
    }
  };

  root.Gush = Gush;
})();


Gush.initialize();
