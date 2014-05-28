(function(){
  var root = this,
    socket;

  var Gush = {
    initialize: function(){
      console.log("Hello from gush");
      this.registerSocket();
    },

    registerSocket: function(){
      socket = new EventSource("/subscribe");

      socket.onopen    = this.onOpen;
      socket.onerror   = this.onError;
      socket.onmessage = this.onMessage;
      socket.onclose   = this.onClose;
    },

    onOpen: function(){
      console.log("Socket has been opened!");
    },

    onError: function(error){
      console.log(error);
    },

    onMessage: function(message){
      console.log(message);
    },

    onClose: function(){
      console.log("Connection closed");
    }
  };

  root.Gush = Gush;
})();


Gush.initialize();
