package  com.laifeng.controls
{
	import com.adobe.images.JPGEncoder;
	import com.laifeng.config.LiveConfig;
	import com.laifeng.config.NoticeKey;
	import com.laifeng.config.UIKey;
	import com.laifeng.event.MEvent;
	import com.laifeng.interfaces.IUI;
	import com.laifeng.view.controlbar.ControlbarView;
	import com.laifeng.view.error.ErrorView;
	import com.laifeng.view.loading.LoadingView;
	import com.laifeng.view.log.LogView;
	import com.laifeng.view.plugs.PluginView;
	import com.laifeng.view.video.Video2;
	import com.laifeng.view.video.VideoV;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import lf.media.core.component.button.ButtonShape;
	import lf.media.core.util.Console;
	import lf.media.core.util.Tweener;
	
	/**********************************************************
	 * UIManage
	 * 
	 * Author         : mj
	 * Description :
	 * 			VIEW 管理器，所有VIEW 的 OPEN CLOSE DESTROY 
	 *          都需统一在此实现
	 ***********************************************************/

	public class UIManage
	{
		
		public static const UI_STATE_OPEN:String     =  "OPEN";
		public static const UI_STATE_CLOSED:String = "CLOSED";
		
		public const totalLayer:int = 6;
		
		
		public function UIManage()
		{
			ExternalInterface.addCallback("_flash_player_uploadimg",_flash_player_uploadimg);
			if(_instance != null){
				return;
			}
		}
		
		
		
		public function playerInited():void{
			_btnSwitchRoom.visible = LiveConfig.get.initOption.showSwitchRoom;
		}
		
		public function start(stage:Stage):void{
			if(_initComplete) true;
			this._stage = stage;
			this._stage.addChild(_layerBg);
			this.stage.addEventListener(Event.RESIZE,listenerStageHandler);
			
			Notification.get.addEventListener(NoticeKey.OPEN_UI,openUiHandler);
			Notification.get.addEventListener(NoticeKey.CLOSE_UI,closeUiHandler);
			Notification.get.addEventListener(NoticeKey.SET_WH_BY_JS,jsControlWHHandler);
			Notification.get.addEventListener(NoticeKey.N_SET_BARRAGE_FULLSCREEN_INPUT, fullScreenInputHandler);
			
			initUis();
			
			_layerVideo = _layerDic[getUI(UIKey.UI_VIDEO).level];
			_layerVideo.buttonMode = true;
			_layerBg.buttonMode = true;
			
			initContexMenu();
			
			this._stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,
																				uncaughtErrorHandler);
			
			this._stage.addEventListener(FullScreenEvent.FULL_SCREEN,listenerScreenHandler);
			
			
			_btnSwitchRoom.addEventListener(MouseEvent.MOUSE_MOVE,mouseInVideoHandler);
			_layerVideo.addEventListener(MouseEvent.MOUSE_MOVE,mouseInVideoHandler);
			this._stage.addEventListener(Event.MOUSE_LEAVE,mouseLeaveHandler);
			
			_initComplete = true;
		}
		
		
		private  function initUis():void{
			
			var layer:Sprite;
			for(var i:int=0; i<totalLayer; i++){
				layer = new Sprite();
				_layerDic[i]=layer
				_stage.addChild(layer);
			}
			
			var switchRoomLayer:Sprite = new Sprite();
			_stage.addChild(switchRoomLayer);
			 _btnSwitchRoom = new ButtonShape(new Skin2_btn_switchroom());
			_stage.addChild(_btnSwitchRoom);
			_btnSwitchRoom.x = 10;
			_btnSwitchRoom.y = _stage.stageHeight - 30;
			
			
			_btnSwitchRoom.addEventListener(MouseEvent.CLICK,switchRoomHandler);
			
			var roomList:Array = [60900,71213,62867];
			var roomId:int = int(LiveConfig.get.initOption.roomId);
			
			if(roomList.indexOf(roomId)>=0){
				addUI(UIKey.UI_VIDEO,                new Video2());
			}else{
				addUI(UIKey.UI_VIDEO,                new VideoV());
			}
			//addUI(UIKey.UI_VIDEO,                new VideoV());
			//addUI(UIKey.UI_VIDEO,                new Video2());
			addUI(UIKey.UI_LOADING,           new LoadingView());
			addUI(UIKey.UI_ERROR,    		     new ErrorView());
			addUI(UIKey.UI_LOG,                     new LogView());
			addUI(UIKey.UI_CONTROLBAR,    new ControlbarView());
			addUI(UIKey.UI_PLUGS,                 new PluginView());
			//addUI(UIKey.UI_CMD,                    new CmdView());
			//addUI(UIKey.UI_BARRAGE,           new BarrageView());
			//addUI(UIKey.UI_GIFT_SHOW,       new GiftShowV());
			//addUI(UIKey.UI_COUNTDOWN,    new CountdownV());
			//addUI(UIKey.UI_BACKGROUND,   new BackgroundV());
			//addUI(UIKey.UI_INPUT,                 new BInputPanel());
		}
		
		private function initContexMenu():void{
			_contextMenu                    =  new ContextMenu();
			_layerVideo.contextMenu = _contextMenu;
			_layerBg.contextMenu      = _contextMenu;
			
			
			var versionItem:ContextMenuItem = new ContextMenuItem(LiveConfig.BUILD_TIME);
			_contextMenu.customItems.push(versionItem);
			
			var itemLog:ContextMenuItem = new ContextMenuItem("视频信息");
			_contextMenu.customItems.push(itemLog);
			itemLog.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,itemSelectHandler);
			
			
			var itemCmd:ContextMenuItem = new ContextMenuItem("CMD");
			_contextMenu.customItems.push(itemCmd);
			itemCmd.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,openCmdHandler);
			/*
			var itemGpu:ContextMenuItem = new ContextMenuItem("尝试开启硬件加速");
			_contextMenu.customItems.push(itemGpu);
			itemGpu.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,openGpuHandler);
			*/
			
		}
		
		private function itemSelectHandler(event:ContextMenuEvent):void{
				if(getUI(UIKey.UI_LOG).uiState == UI_STATE_OPEN){
					closeUI(UIKey.UI_LOG);
				}else{
					openUI(UIKey.UI_LOG);
				}
		}
		
		
		
		private function openCmdHandler(event:ContextMenuEvent):void{
			if(getUI(UIKey.UI_CMD).uiState == UI_STATE_OPEN){
				closeUI(UIKey.UI_CMD);
			}else{
				openUI(UIKey.UI_CMD);
			}
		}
		
		
		
		public function addUI(uiKey:String,ui:IUI):void{
			_uiDic[uiKey] = ui;
			ui.uiState = UI_STATE_CLOSED;
		}
		
		
		private function openUiHandler(event:MEvent):void{
			openUI(event.data as String);
		}
		
		private function closeUiHandler(event:MEvent):void{
			closeUI(event.data as String);
		}
		
		
		public function openUI(uiKey:String):void{
			
			LiveConfig.get.defaultWidth = _stage.stageWidth;
			LiveConfig.get.defaultHeight = _stage.stageHeight;
			
			
			if(uiKey == UIKey.UI_PLUGS){
				LFExtenrnalInterface.get.showRecommend(1);
				return;
			}
			
			
			var ui:IUI = _uiDic[uiKey];
			if(ui == null){
				return;
			}
			
			
			if(ui){
				
					if(getUI(uiKey).uiState == UI_STATE_OPEN){
						this.closeUI(uiKey);
					}
					
				
				if(uiKey == UIKey.UI_CONTROLBAR){
					if(!LiveConfig.get.rootRightData.isShowCtrBar){
						return;
					}
					
					if(LiveConfig.get.defaultWidth <100){
						return;
					}
				}
				
				
				if(uiKey == UIKey.UI_BARRAGE){
					if(!LiveConfig.get.initOption.showHorn){ //是否展示金喇叭
						return;
					}
				}
				
				var layer:Sprite = _layerDic[ui.level];
				layer.addChild(ui as Sprite);
				ui.open();
				ui.screenChange(LiveConfig.get.defaultWidth,LiveConfig.get.defaultHeight);
				ui.uiState = UI_STATE_OPEN;
				
				if(uiKey == UIKey.UI_CONTROLBAR){
					(ui as Sprite).alpha = 0;
					Tweener.to(ui as Sprite,0.5,{alpha:1});
				}
			}
		}
		
		
		public function closeUI(uiKey:String):void{
			
			if(uiKey == UIKey.UI_PLUGS){
				LFExtenrnalInterface.get.showRecommend(0);
				return;
			}
			
			
			
			var ui:IUI = _uiDic[uiKey];
			if(ui){
				var layer:Sprite = _layerDic[ui.level];
				if(layer.contains(ui as Sprite)){
					if(uiKey == UIKey.UI_CONTROLBAR){
						(ui as Sprite).alpha = 1;
						Tweener.to(ui as Sprite,1,{alpha:0,onComplete:closeControlBar});
					}else{
						layer.removeChild(ui as Sprite);
						ui.close();
						ui.uiState = UI_STATE_CLOSED;
					}
				}
			}
		}
		
		
		private function closeControlBar():void{
			var layer:Sprite = _layerDic[getUI(UIKey.UI_CONTROLBAR).level];
			var ui:IUI            = _uiDic[UIKey.UI_CONTROLBAR];
			layer.removeChild(ui as Sprite);
			ui.close();
			ui.uiState = UI_STATE_CLOSED;
		}
		
		
		
		private function jsControlWHHandler(event:MEvent):void{
			
			var data:Object = event.data;
			var bgW:int      = data["width"];
			var bgH:int       = data["height"];
			
			LiveConfig.get.defaultWidth = bgW;
			LiveConfig.get.defaultHeight = bgH;
			
			resizeScreen(bgW,bgH);
		}
		
		private function fullScreenInputHandler(evt:Event = null):void
		{
			if(LiveConfig.get.initOption==null) return;
			if(LiveConfig.get.initOption.appId != 101){//非来疯平台  屏蔽来疯全屏输入业务
				return;
			}
			
			if (LiveConfig.isFullScreenInteractive && 
				UIManage.get.stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE)
			{
				if(getUI(UIKey.UI_INPUT).uiState != UI_STATE_OPEN)
					openUI(UIKey.UI_INPUT);
			}
			else
			{
				//if(getUI(UIKey.UI_INPUT).uiState != UI_STATE_CLOSED)
					//closeUI(UIKey.UI_INPUT);
			}

		}
		
		private function listenerScreenHandler(event:FullScreenEvent):void{
				var fullScreen:Boolean  =event.fullScreen;
				
				var bgW:int = fullScreen? flash.system.Capabilities.screenResolutionX:LiveConfig.get.defaultWidth;
				var bgH:int  = fullScreen? flash.system.Capabilities.screenResolutionY:LiveConfig.get.defaultHeight;
				
				resizeScreen(bgW,bgH);
		}
		
		
		
		public function resizeScreen(viewPortW:int,viewPortH:int):void{
			LiveConfig.get.defaultWidth = viewPortW;
			LiveConfig.get.defaultHeight = viewPortH;
			
			var ui:IUI;
			for(var key:String in _uiDic){
				ui = _uiDic[key];
				ui.screenChange(viewPortW,viewPortH);
			}
			updataBg(viewPortW,viewPortH);
			//全屏下是否显示输入框的处理
			fullScreenInputHandler();
			
			_btnSwitchRoom.x = 10;
			_btnSwitchRoom.y = viewPortH - 30;
		}
		
		
		private function listenerStageHandler(event:Event):void{
			var w:int = _stage.stageWidth;
			var h:int  = _stage.stageHeight;
			
			if(w != _lastStageWidth){
				_lastStageWidth = w;
				resizeScreen(w,h);
			}
		}
		
		
		
		private function openGpuHandler(event:ContextMenuEvent):void{
			var item:ContextMenuItem = event.target as ContextMenuItem;
			switch(item.caption){
				case "关闭硬件加速" :
					item.caption = "尝试开启硬件加速";
					break;
				case "尝试开启硬件加速" :
					item.caption = "关闭硬件加速";
					break;
			}
		}
		
		
		
		public function get stage():Stage{
			return _stage;
		}
		
		public function getUI(uiKey:String):IUI{
			return _uiDic[uiKey];
		}
		
		
		private function updataBg(width:int,height:int):void{
			var color : uint = 0x000000;
			_layerBg.graphics.clear();
			_layerBg.graphics.beginFill(color);
			_layerBg.graphics.drawRect(0, 0, width, height);
			_layerBg.graphics.endFill();
		}
		
		public static  function get get():UIManage{
			_instance = _instance==null? new UIManage():_instance;
			
			return _instance;
		}
		
		
		private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
		{
			Console.log(event.error);
		}
		
		
		private function mouseInVideoHandler(event:MouseEvent):void{
			
			if(LiveConfig.liveStatus<2) return;
			
			if(getUI(UIKey.UI_CONTROLBAR).uiState == UI_STATE_CLOSED){
				openUI(UIKey.UI_CONTROLBAR);
			}else{
				LiveConfig.mouseInTime = getTimer();
			}
		}
		
		
		private function mouseLeaveHandler(event:Event):void{
			//todo  mouse leave stage
		}
		
		/**
		 * 切换其他房间
		 */
		private function switchRoomHandler(event:MouseEvent):void{
			UIManage.get.stage.displayState = StageDisplayState.NORMAL;
			LFExtenrnalInterface.get.switchRoom();
		}
		
		
		public function _flash_player_uploadimg(callbackName:String):void{
			
			_upImgCbName = callbackName;
			
			var bmd:BitmapData;
			if(getUI(UIKey.UI_VIDEO).uiState == UI_STATE_OPEN){
				var pw:int = (getUI(UIKey.UI_VIDEO) as DisplayObject).width;
				var ph:int = (getUI(UIKey.UI_VIDEO) as DisplayObject).height;
				pw= pw==0? 320:pw;
				ph = ph==0? 500:ph;
				bmd = new BitmapData(pw,ph,false,0x000000);
				bmd.draw(getUI(UIKey.UI_VIDEO) as DisplayObject);
			}else{
				bmd = new BitmapData(160,160,false,0x000000);
			}
			
			var encoder:JPGEncoder = new JPGEncoder(90); 
			var imgBytes:ByteArray        = encoder.encode(bmd);
			
			var url:String = "http://v.laifeng.com/recruit/upimg?name=report&size=400&" +
				"url=/recruit/upimg&filename="+Math.floor(Math.random()*9999999)+".jpg";
			
			var path:String = encodeURI(url);
			var req:URLRequest = new URLRequest(path);
			var loader:URLLoader = new URLLoader(); 
			//data值就为图片编码数据ByteArray;  
			req.method = URLRequestMethod.POST; 
			req.data   = imgBytes;
			
			req.contentType = "application/octet-stream";  
			loader.addEventListener(Event.COMPLETE, respCompleteHandler);  
			loader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityErrorHandler);
			loader.load(req);
			
			bmd.dispose();
			bmd = null;
			
		}
		
		/**
		 * 图片成功上传到服务器
		 */
		private function respCompleteHandler(event:Event):void
		{
			ExternalInterface.call(_upImgCbName,(event.target as URLLoader).data);
			var urlLoader:URLLoader = event.target as URLLoader;
			if(urlLoader == null) return;
			urlLoader.removeEventListener(Event.COMPLETE, respCompleteHandler);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
		}
		
		/**
		 *流错误
		 */
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			var str:String = '{"response":{"code":1,"msg":"连接图片服务器失败"}}';
			ExternalInterface.call(_upImgCbName,str);
		}
		
		/**
		 *安全沙箱错误
		 */
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			var str:String = '{"response":{"code":1,"msg":"上传图片安全沙箱错误!"}}' ;
			ExternalInterface.call(_upImgCbName,str);
		}
		
		
		
		private static var _instance:UIManage;
		private var _stage:Stage;
		private var _uiDic:Dictionary = new Dictionary();
		
		private var _layerBg:Sprite = new Sprite();
		private var _contextMenu:ContextMenu;
		/**存储层级*/
		private var _layerDic:Dictionary = new Dictionary();
		
		private var _layerVideo:Sprite;
		
		private var _lastStageWidth:int = 0;
		
		private var _btnSwitchRoom:ButtonShape;
		//上传图片结果回调JS
		private var _upImgCbName:String = "";
		private var _initComplete:Boolean = false;
		
		
		
	}
}