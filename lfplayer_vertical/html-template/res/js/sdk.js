var SDK = function(){};

var swfID = "";

 SDK.prototype = {
 
	 init:function(option){
			var roomId          = option["roomId"];
			var roomType     = option["roomType"]
			var pW              = option["width"];
			var pH               = option["height"];
			var flashContentId  = option["flashContentId"];
			var swfUrl          = option["swfUrl"];
			swfID                  = option["swfId"];
		       
			var swfVersionStr = "10.2.0";
	        var xiSwfUrlStr = "playerProductInstall.swf";
			
			var flashvars = {};
			flashvars.room_id= roomId;  //98154982  840  9713 53473
	
			flashvars.autoplay="1";
			flashvars.userid="8888";
			//flashvars.playerwidth= pW;  //560   800   520
			//flashvars.playerheight= pH; //420  450    390
			flashvars.fullscreen="1";
			flashvars.showPlugs = 1;
			flashvars.showHorn = 1;  //0:隐藏  1:显示
			flashvars.roomType = roomType;
			flashvars.brower = "";
			
			var params = {};
	        params.quality = "high";
	        params.bgcolor = "#FFFFFF";
	        params.allowscriptaccess = "always"
			params.allowfullscreen = "true";
			params.allowFullScreenInteractive="true"
			
			var attributes   = {};
	        attributes.id    = swfID;
	        attributes.name  = swfID;
	        attributes.align = "middle";
			attributes.allowFullScreenInteractive = "true";
			
			
			 swfobject.embedSWF(
	                swfUrl, flashContentId, 
	                "100%", "100%", 
	                swfVersionStr, xiSwfUrlStr, 
	                flashvars, params, attributes
				);
			
			swfobject.createCSS('#'+flashContentId, "display:block;text-align:left;");
	 },
	 
	 
	 getVideo:function(){
	 	console.log(swfID,$);
	 	return $('#'+swfID)[0];
	 },
	 
	 stopLive:function(){
	 	this.getVideo()["stopLive"]();		
	 }
 
 
 };